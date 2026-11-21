export type VerificationStatus =
  | "UNVERIFIED"
  | "PENDING_REVIEW"
  | "VERIFIED"
  | "REJECTED";

export interface AdminUser {
  id: string;
  email: string;
  fullName: string;
  role: "ADMIN";
}

export interface KycItem {
  id: string;
  userId: string;
  farmName: string;
  region: string;
  city?: string | null;
  address?: string | null;
  idCardFrontUrl?: string | null;
  idCardBackUrl?: string | null;
  avatarUrl?: string | null;
  coverUrl?: string | null;
  createdAt: string;
  updatedAt: string;
  user: {
    id: string;
    fullName: string;
    phoneNumber?: string | null;
    email?: string | null;
    verificationStatus: VerificationStatus;
  };
}

export interface FarmerItem {
  id: string;
  userId: string;
  farmName: string;
  region: string;
  city?: string | null;
  address?: string | null;
  avatarUrl?: string | null;
  coverUrl?: string | null;
  rating: number;
  reviewCount: number;
  createdAt: string;
  user: {
    id: string;
    fullName: string;
    phoneNumber?: string | null;
    email?: string | null;
    verificationStatus: VerificationStatus;
  };
  _count: {
    products: number;
    reviews: number;
  };
}

export interface ProductItem {
  id: string;
  title: string;
  description?: string | null;
  category: string;
  price: number;
  unit: string;
  stockQuantity: number;
  isActive: boolean;
  images: string[];
  createdAt: string;
  farmer: {
    id: string;
    farmName: string;
    region: string;
    user: {
      fullName: string;
      phoneNumber?: string | null;
    };
  };
}

export interface OrderItem {
  id: string;
  totalAmount: number;
  status: "PENDING" | "IN_PROGRESS" | "CONFIRMED" | "COMPLETED" | "CANCELLED";
  paymentStatus?: string;
  createdAt: string;
  client?: {
    fullName: string;
    phoneNumber?: string | null;
    email?: string | null;
  };
  user?: {
    fullName: string;
    phoneNumber?: string | null;
    email?: string | null;
  };
  items: Array<{
    id: string;
    quantity: number;
    unitPrice: number;
    product: {
      title: string;
      price: number;
      unit: string;
      farmer: {
        farmName: string;
        region: string;
      };
    };
  }>;
}

export interface PayoutItem {
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

export interface DashboardKpis {
  pendingKycCount: number;
  totalFarmersCount: number;
  totalProductsCount: number;
  totalOrdersCount: number;
  totalGmv: number;
}

