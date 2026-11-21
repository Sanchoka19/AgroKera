import prisma from "../../lib/prisma.ts";
import {
  jsonResponse,
  errorResponse,
  createAuthToken,
  extractAuthUserId,
  hashPassword,
  verifyPassword,
} from "../utils.ts";

const ADMIN_SECRET =
  process.env.ADMIN_SECRET ||
  process.env.ADMIN_PASSWORD ||
  "agrokera_admin_2026";
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@agrokera.ge";

/**
 * Validates whether the incoming request is authorized as an Admin.
 * Accepts either:
 * 1. Bearer token belonging to an ADMIN user.
 * 2. `x-admin-key` header matching ADMIN_SECRET.
 */
async function authorizeAdmin(request: Request): Promise<boolean> {
  const adminKey = request.headers.get("x-admin-key");
  if (adminKey && adminKey === ADMIN_SECRET) {
    return true;
  }

  const userId = extractAuthUserId(request);
  if (!userId) return false;

  // Check if user has ADMIN role in database
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { role: true },
  });

  return user?.role === "ADMIN";
}

/**
 * Handles all `/api/admin/*` routes.
 */
export async function handleAdminRoute(
  request: Request,
  url: URL,
  path: string,
  method: string
): Promise<Response | null> {
  if (!path.startsWith("/api/admin")) {
    return null;
  }

  // =========================================================================
  // 1. ADMIN AUTH LOGIN
  // =========================================================================
  if (method === "POST" && path === "/api/admin/auth/login") {
    try {
      const body = (await request.json().catch(() => ({}))) as {
        email?: string;
        password?: string;
        adminKey?: string;
      };

      const email = body.email?.trim().toLowerCase();
      const password = body.password?.trim();
      const adminKey = body.adminKey?.trim();

      let authenticatedAdmin: any = null;

      // Option A: Admin Secret Key
      if (adminKey) {
        if (adminKey !== ADMIN_SECRET) {
          return errorResponse("არასწორი ადმინის საიდუმლო გასაღები", 401);
        }
        authenticatedAdmin = await prisma.user.findFirst({
          where: { role: "ADMIN" },
        });
      }
      // Option B: Email & Password
      else if (email && password) {
        const isMasterEmail = email === ADMIN_EMAIL.toLowerCase();

        const dbAdmin = await prisma.user.findFirst({
          where: {
            email: { equals: email, mode: "insensitive" },
            role: "ADMIN",
          },
        });

        if (!dbAdmin && !isMasterEmail) {
          return errorResponse("არასწორი ელ-ფოსტა ან პაროლი", 401);
        }

        let isPasswordCorrect = false;

        if (dbAdmin?.passwordHash) {
          isPasswordCorrect = verifyPassword(password, dbAdmin.passwordHash);
        } else if (password === ADMIN_SECRET) {
          isPasswordCorrect = true;
          if (dbAdmin) {
            await prisma.user.update({
              where: { id: dbAdmin.id },
              data: { passwordHash: hashPassword(password) },
            });
          }
        }

        if (!isPasswordCorrect) {
          return errorResponse("არასწორი ელ-ფოსტა ან პაროლი", 401);
        }

        authenticatedAdmin = dbAdmin;
      } else {
        return errorResponse("შეიყვანეთ ელ-ფოსტა და პაროლი ან საიდუმლო გასაღები", 400);
      }

      // If no admin user exists in DB yet, create the default admin user with hashed password
      if (!authenticatedAdmin) {
        authenticatedAdmin = await prisma.user.create({
          data: {
            email: ADMIN_EMAIL,
            fullName: "AgroKera ადმინისტრატორი",
            role: "ADMIN",
            verificationStatus: "VERIFIED",
            passwordHash: hashPassword(ADMIN_SECRET),
          },
        });
      }

      const token = createAuthToken(authenticatedAdmin.id);
      return jsonResponse({
        token,
        admin: {
          id: authenticatedAdmin.id,
          email: authenticatedAdmin.email,
          fullName: authenticatedAdmin.fullName,
          role: "ADMIN",
        },
      });
    } catch (err) {
      console.error("[Admin Login Error]:", err);
      return errorResponse("ავტორიზაციის შეცდომა", 500);
    }
  }

  // All other `/api/admin/*` endpoints require Admin Authorization
  const isAuthorized = await authorizeAdmin(request);
  if (!isAuthorized) {
    return errorResponse("წვდომა შეზღუდულია: საჭიროა ადმინისტრატორის უფლებები", 403);
  }

  // =========================================================================
  // 2. DASHBOARD KPI STATS
  // =========================================================================
  if (method === "GET" && path === "/api/admin/stats") {
    try {
      const [
        pendingKycCount,
        totalFarmersCount,
        totalProductsCount,
        totalOrdersCount,
        completedOrders,
        recentOrders,
        recentKycRequests,
      ] = await Promise.all([
        prisma.user.count({
          where: { verificationStatus: "PENDING_REVIEW" },
        }),
        prisma.farmerProfile.count(),
        prisma.product.count(),
        prisma.order.count(),
        prisma.order.findMany({
          where: { status: "COMPLETED" },
          select: { totalAmount: true },
        }),
        prisma.order.findMany({
          take: 6,
          orderBy: { createdAt: "desc" },
          include: {
            client: { select: { fullName: true, phoneNumber: true } },
            items: {
              take: 2,
              include: { product: { select: { title: true } } },
            },
          },
        }),
        prisma.farmerProfile.findMany({
          where: {
            user: { verificationStatus: "PENDING_REVIEW" },
          },
          take: 6,
          orderBy: { updatedAt: "desc" },
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                phoneNumber: true,
                email: true,
                verificationStatus: true,
              },
            },
          },
        }),
      ]);

      const totalGmv = completedOrders.reduce(
        (acc, o) => acc + (o.totalAmount || 0),
        0
      );

      return jsonResponse({
        kpis: {
          pendingKycCount,
          totalFarmersCount,
          totalProductsCount,
          totalOrdersCount,
          totalGmv: Math.round(totalGmv * 100) / 100,
        },
        recentOrders,
        recentKycRequests,
      });
    } catch (err) {
      console.error("[Admin Stats Error]:", err);
      return errorResponse("სტატისტიკის ჩატვირთვა ვერ მოხერხდა", 500);
    }
  }

  // =========================================================================
  // 3. KYC QUEUE & DETAILS
  // =========================================================================
  if (method === "GET" && path === "/api/admin/kyc") {
    try {
      const statusFilter = url.searchParams.get("status") || "PENDING_REVIEW";

      const whereClause =
        statusFilter === "ALL"
          ? {}
          : {
              user: {
                verificationStatus: statusFilter as
                  | "UNVERIFIED"
                  | "PENDING_REVIEW"
                  | "VERIFIED"
                  | "REJECTED",
              },
            };

      const kycList = await prisma.farmerProfile.findMany({
        where: whereClause,
        orderBy: { updatedAt: "desc" },
        include: {
          user: {
            select: {
              id: true,
              fullName: true,
              phoneNumber: true,
              email: true,
              avatarUrl: true,
              verificationStatus: true,
              createdAt: true,
              updatedAt: true,
            },
          },
        },
      });

      return jsonResponse({ items: kycList });
    } catch (err) {
      console.error("[Admin KYC Error]:", err);
      return errorResponse("ვერიფიკაციის რიგის ჩატვირთვა ვერ მოხერხდა", 500);
    }
  }

  // Review KYC (Approve or Reject)
  const kycReviewMatch = path.match(/^\/api\/admin\/kyc\/([^/]+)\/review$/);
  if (method === "POST" && kycReviewMatch) {
    try {
      const farmerId = kycReviewMatch[1];
      const body = (await request.json().catch(() => ({}))) as {
        status?: "VERIFIED" | "REJECTED";
        rejectionReason?: string;
      };

      if (!body.status || !["VERIFIED", "REJECTED"].includes(body.status)) {
        return errorResponse("სტატუსი უნდა იყოს VERIFIED ან REJECTED", 400);
      }

      const farmer = await prisma.farmerProfile.findUnique({
        where: { id: farmerId },
        include: { user: true },
      });

      if (!farmer) {
        return errorResponse("ფერმერი ვერ მოიძებნა", 404);
      }

      // Update user verification status
      await prisma.user.update({
        where: { id: farmer.userId },
        data: { verificationStatus: body.status },
      });

      // Send system notification to farmer
      const title =
        body.status === "VERIFIED"
          ? "ვერიფიკაცია წარმატებით დასრულდა"
          : "ვერიფიკაცია ვერ დადასტურდა";

      const message =
        body.status === "VERIFIED"
          ? "თქვენი მეურნეობა წარმატებით ვერიფიცირდა. თქვენ უკვე შეგიძლიათ პროდუქტების დამატება და გამოქვეყნება!"
          : `თქვენი საბუთები ვერ დადასტურდა: ${
              body.rejectionReason?.trim() || "გთხოვთ ატვირთოთ მკაფიო ფოტოები."
            }`;

      await prisma.notification.create({
        data: {
          userId: farmer.userId,
          title,
          body: message,
          category: "kyc",
          isRead: false,
        },
      });

      return jsonResponse({
        success: true,
        farmerId,
        newStatus: body.status,
        message:
          body.status === "VERIFIED"
            ? "ფერმერი წარმატებით ვერიფიცირდა"
            : "ფერმერის ვერიფიკაცია დახარვეზდა",
      });
    } catch (err) {
      console.error("[Admin Review KYC Error]:", err);
      return errorResponse("ვერიფიკაციის სტატუსის განახლება ვერ მოხერხდა", 500);
    }
  }

  // =========================================================================
  // 4. FARMERS DIRECTORY
  // =========================================================================
  if (method === "GET" && path === "/api/admin/farmers") {
    try {
      const query = url.searchParams.get("q")?.trim().toLowerCase() || "";
      const region = url.searchParams.get("region") || "";

      const farmers = await prisma.farmerProfile.findMany({
        where: {
          AND: [
            region ? { region } : {},
            query
              ? {
                  OR: [
                    { farmName: { contains: query, mode: "insensitive" } },
                    {
                      user: {
                        fullName: { contains: query, mode: "insensitive" },
                      },
                    },
                    {
                      user: {
                        phoneNumber: { contains: query, mode: "insensitive" },
                      },
                    },
                  ],
                }
              : {},
          ],
        },
        orderBy: { createdAt: "desc" },
        include: {
          user: {
            select: {
              id: true,
              fullName: true,
              phoneNumber: true,
              email: true,
              verificationStatus: true,
              createdAt: true,
            },
          },
          _count: {
            select: {
              products: true,
              reviews: true,
            },
          },
        },
      });

      return jsonResponse({ items: farmers });
    } catch (err) {
      console.error("[Admin Farmers Error]:", err);
      return errorResponse("ფერმერების სიის ჩატვირთვა ვერ მოხერხდა", 500);
    }
  }

  // =========================================================================
  // 5. PRODUCTS MODERATION
  // =========================================================================
  if (method === "GET" && path === "/api/admin/products") {
    try {
      const query = url.searchParams.get("q")?.trim().toLowerCase() || "";
      const category = url.searchParams.get("category") || "";

      const products = await prisma.product.findMany({
        where: {
          AND: [
            category ? { category } : {},
            query
              ? {
                  OR: [
                    { title: { contains: query, mode: "insensitive" } },
                    { description: { contains: query, mode: "insensitive" } },
                    {
                      farmer: {
                        farmName: { contains: query, mode: "insensitive" },
                      },
                    },
                  ],
                }
              : {},
          ],
        },
        orderBy: { createdAt: "desc" },
        include: {
          farmer: {
            select: {
              id: true,
              farmName: true,
              region: true,
              user: { select: { fullName: true, phoneNumber: true } },
            },
          },
        },
      });

      const formattedProducts = products.map((p) => ({
        ...p,
        price: p.pricePerUnit,
        isActive: p.isAvailable,
      }));

      return jsonResponse({ items: formattedProducts });
    } catch (err) {
      console.error("[Admin Products Error]:", err);
      return errorResponse("პროდუქციის სიის ჩატვირთვა ვერ მოხერხდა", 500);
    }
  }

  // Toggle Product Active / Inactive
  const productToggleMatch = path.match(
    /^\/api\/admin\/products\/([^/]+)\/toggle$/
  );
  if (method === "PATCH" && productToggleMatch) {
    try {
      const productId = productToggleMatch[1];
      const product = await prisma.product.findUnique({
        where: { id: productId },
        select: { id: true, isAvailable: true },
      });

      if (!product) {
        return errorResponse("პროდუქტი ვერ მოიძებნა", 404);
      }

      const updated = await prisma.product.update({
        where: { id: productId },
        data: { isAvailable: !product.isAvailable },
      });

      return jsonResponse({
        success: true,
        productId,
        isActive: updated.isAvailable,
      });
    } catch (err) {
      console.error("[Admin Toggle Product Error]:", err);
      return errorResponse("პროდუქტის სტატუსის განახლება ვერ მოხერხდა", 500);
    }
  }

  // =========================================================================
  // 6. ORDERS MONITORING
  // =========================================================================
  if (method === "GET" && path === "/api/admin/orders") {
    try {
      const status = url.searchParams.get("status") || "";

      const orders = await prisma.order.findMany({
        where: status ? { status: status as any } : {},
        orderBy: { createdAt: "desc" },
        include: {
          client: {
            select: {
              fullName: true,
              phoneNumber: true,
              email: true,
            },
          },
          items: {
            include: {
              product: {
                select: {
                  title: true,
                  pricePerUnit: true,
                  unit: true,
                  farmer: { select: { farmName: true, region: true } },
                },
              },
            },
          },
        },
      });

      return jsonResponse({ items: orders });
    } catch (err) {
      console.error("[Admin Orders Error]:", err);
      return errorResponse("შეკვეთების სიის ჩატვირთვა ვერ მოხერხდა", 500);
    }
  }

  // =========================================================================
  // 7. PAYOUTS & BANK DETAILS
  // =========================================================================
  if (method === "GET" && path === "/api/admin/payouts") {
    try {
      // Aggregate completed orders per farmer
      const completedOrders = await prisma.order.findMany({
        where: { status: "COMPLETED" },
        include: {
          items: {
            include: {
              product: {
                select: {
                  farmerId: true,
                  farmer: {
                    select: {
                      id: true,
                      farmName: true,
                      region: true,
                      user: {
                        select: {
                          fullName: true,
                          phoneNumber: true,
                          email: true,
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      });

      // Group totals per farmer
      const farmerPayoutMap = new Map<
        string,
        {
          farmerId: string;
          farmName: string;
          farmerName: string;
          phoneNumber: string;
          region: string;
          totalCompletedOrders: number;
          totalGrossAmount: number;
          commissionFee: number;
          netPayoutAmount: number;
        }
      >();

      for (const order of completedOrders) {
        const processedFarmersInOrder = new Set<string>();

        for (const item of order.items) {
          const fId = item.product.farmerId;
          const farmerInfo = item.product.farmer;
          const itemTotal =
            typeof item.subtotal === "number" && !isNaN(item.subtotal) && item.subtotal > 0
              ? item.subtotal
              : (item.quantity || 1) * (item.pricePerUnit || 0);

          if (!farmerPayoutMap.has(fId)) {
            farmerPayoutMap.set(fId, {
              farmerId: fId,
              farmName: farmerInfo?.farmName || "მეურნეობა",
              farmerName: farmerInfo?.user?.fullName || "უცნობი",
              phoneNumber: farmerInfo?.user?.phoneNumber || "",
              region: farmerInfo?.region || "",
              totalCompletedOrders: 0,
              totalGrossAmount: 0,
              commissionFee: 0,
              netPayoutAmount: 0,
            });
          }

          const entry = farmerPayoutMap.get(fId)!;
          entry.totalGrossAmount += itemTotal;
          processedFarmersInOrder.add(fId);
        }

        for (const fId of processedFarmersInOrder) {
          const entry = farmerPayoutMap.get(fId);
          if (entry) {
            entry.totalCompletedOrders += 1;
          }
        }
      }

      // Calculate net amounts (e.g. 5% platform fee)
      const payoutList = Array.from(farmerPayoutMap.values()).map((p) => {
        const fee = Math.round(p.totalGrossAmount * 0.05 * 100) / 100;
        return {
          ...p,
          totalGrossAmount: Math.round(p.totalGrossAmount * 100) / 100,
          commissionFee: fee,
          netPayoutAmount: Math.round((p.totalGrossAmount - fee) * 100) / 100,
        };
      });

      return jsonResponse({ items: payoutList });
    } catch (err) {
      console.error("[Admin Payouts Error]:", err);
      return errorResponse("ანგარიშსწორების რეესტრის ჩატვირთვა ვერ მოხერხდა", 500);
    }
  }

  return errorResponse("ადმინ ენდფოინთი არ არსებობს", 404);
}

