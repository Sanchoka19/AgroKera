import { PrismaClient, Role, VerificationStatus, OrderStatus, FulfillmentType, ShipmentStatus } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Seeding AgroKera Neon PostgreSQL database...");

  // 1. Upsert Farmer Users & FarmerProfiles
  const farmersData = [
    {
      userId: "user_farmer_1",
      farmerId: "farmer_1",
      fullName: "ლანა მახარაძე",
      phoneNumber: "+995 599 33 22 11",
      email: "lana@agrokera.ge",
      farmName: "მწვანე ველი",
      region: "კახეთი",
      city: "გურჯაანი",
      address: "გურჯაანი, კახეთი",
      rating: 4.9,
      reviewCount: 80,
      totalRatings: 120,
      isVatPayer: true,
      avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80",
      coverUrl: "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1000&auto=format&fit=crop&q=80",
      about: "„მწვანე ველი“ მდებარეობს კახეთში, გურჯაანის ნაყოფიერ მიწებზე. ჩვენ მოგვყავს ეკოლოგიურად სუფთა, ბიო-სერტიფიცირებული ბოსტნეული და ყურძენი ყოველგვარი ქიმიური დანამატების გარეშე.",
    },
    {
      userId: "user_farmer_2",
      farmerId: "farmer_2",
      fullName: "გიორგი ბერიძე",
      phoneNumber: "+995 599 11 22 33",
      email: "giorgi@agrokera.ge",
      farmName: "გიორგის ფერმა",
      region: "კახეთი",
      city: "თელავი",
      address: "თელავი, კახეთი",
      rating: 4.9,
      reviewCount: 80,
      totalRatings: 95,
      isVatPayer: false,
      avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80",
      coverUrl: "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80",
      about: "საგვარეულო მეურნეობა თელავში. ვამარაგებთ რესტორნებსა და კერძო კლიენტებს ახალი ბოსტნეულითა და მწვანილეულით.",
    },
    {
      userId: "user_farmer_3",
      farmerId: "farmer_3",
      fullName: "დავით ნოზაძე",
      phoneNumber: "+995 599 44 55 66",
      email: "davit@agrokera.ge",
      farmName: "ალაზნის ბაღები",
      region: "კახეთი",
      city: "ყვარელი",
      address: "ყვარელი, კახეთი",
      rating: 4.8,
      reviewCount: 65,
      totalRatings: 110,
      isVatPayer: true,
      avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80",
      coverUrl: "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=1000&auto=format&fit=crop&q=80",
      about: "ალაზნის ველზე გაშენებული მრავალწლიანი ხეხილისა და ციტრუსის ბაღები. 100% ნატურალური და მზით გამთბარი მოსავალი ყვარლიდან.",
    },
  ];

  for (const f of farmersData) {
    await prisma.user.upsert({
      where: { id: f.userId },
      update: {
        fullName: f.fullName,
        phoneNumber: f.phoneNumber,
        email: f.email,
        role: Role.FARMER,
        verificationStatus: VerificationStatus.VERIFIED,
      },
      create: {
        id: f.userId,
        fullName: f.fullName,
        phoneNumber: f.phoneNumber,
        email: f.email,
        role: Role.FARMER,
        verificationStatus: VerificationStatus.VERIFIED,
      },
    });

    await prisma.farmerProfile.upsert({
      where: { id: f.farmerId },
      update: {
        farmName: f.farmName,
        region: f.region,
        city: f.city,
        address: f.address,
        rating: f.rating,
        reviewCount: f.reviewCount,
        totalRatings: f.totalRatings,
        isVatPayer: f.isVatPayer,
        avatarUrl: f.avatarUrl,
        coverUrl: f.coverUrl,
        about: f.about,
      },
      create: {
        id: f.farmerId,
        userId: f.userId,
        farmName: f.farmName,
        region: f.region,
        city: f.city,
        address: f.address,
        rating: f.rating,
        reviewCount: f.reviewCount,
        totalRatings: f.totalRatings,
        isVatPayer: f.isVatPayer,
        avatarUrl: f.avatarUrl,
        coverUrl: f.coverUrl,
        about: f.about,
      },
    });
  }

  // 2. Upsert Sample Client User
  await prisma.user.upsert({
    where: { id: "user_client_1" },
    update: {
      fullName: 'შპს "გემრიელი რესტორანი"',
      phoneNumber: "+995 599 12 34 56",
      email: "client@agrokera.ge",
      role: Role.CLIENT,
      verificationStatus: VerificationStatus.VERIFIED,
    },
    create: {
      id: "user_client_1",
      fullName: 'შპს "გემრიელი რესტორანი"',
      phoneNumber: "+995 599 12 34 56",
      email: "client@agrokera.ge",
      role: Role.CLIENT,
      verificationStatus: VerificationStatus.VERIFIED,
    },
  });

  // 3. Upsert Products
  const productsData = [
    {
      id: "prod_1",
      title: "მწვანილოვანი კომბოსტო",
      category: "ბოსტნეული",
      farmerId: "farmer_2",
      pricePerUnit: 15.0,
      discountPercent: 20,
      unit: "კგ",
      stockQuantity: 120.0,
      stockStatus: "მარაგშია",
      rating: 4.9,
      reviewCount: 80,
      imageUrl: "https://images.unsplash.com/photo-1550142414-a81e12541000?w=600&auto=format&fit=crop&q=80",
      description: "ახალი, ხრაშუნა და ნატურალური მწვანილოვანი კომბოსტო პირდაპირ გიორგის ფერმიდან. იდეალურია სალათებისთვის და ჯანსაღი კერძებისთვის. მდიდარია C და K ვიტამინებით.",
    },
    {
      id: "prod_2",
      title: "ბულგარული წიწაკა",
      category: "ბოსტნეული",
      farmerId: "farmer_2",
      pricePerUnit: 15.0,
      discountPercent: 20,
      unit: "კგ",
      stockQuantity: 85.0,
      stockStatus: "მარაგშია",
      rating: 4.9,
      reviewCount: 80,
      imageUrl: "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600&auto=format&fit=crop&q=80",
      description: "ფერადი, წვნიანი და ტკბილი ბულგარული წიწაკა. დაკრეფილია დილით ადრე საუკეთესო არომატისა და სიახლის შესანარჩუნებლად.",
    },
    {
      id: "prod_3",
      title: "ხახვი",
      category: "ბოსტნეული",
      farmerId: "farmer_2",
      pricePerUnit: 15.0,
      discountPercent: 0,
      unit: "კგ",
      stockQuantity: 200.0,
      stockStatus: "მარაგშია",
      rating: 4.9,
      reviewCount: 80,
      imageUrl: "https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=600&auto=format&fit=crop&q=80",
      description: "მშრალი და მაღალი ხარისხის ადგილობრივი ხახვი. ინახება დიდხანს, გამოირჩევა მდიდარი პიკანტური გემოთი.",
    },
    {
      id: "prod_4",
      title: "პომიდორი",
      category: "ბოსტნეული",
      farmerId: "farmer_2",
      pricePerUnit: 15.0,
      discountPercent: 20,
      unit: "კგ",
      stockQuantity: 12.0,
      stockStatus: "იწურება",
      rating: 4.9,
      reviewCount: 80,
      imageUrl: "https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80",
      description: "არომატული ქართული ვარდისფერი პომიდორი. იზრდება ღია გრუნტზე, მზის სითბოში. გამორჩეული წვნიანობა და ნამდვილი ტომატის გემო.",
    },
    {
      id: "prod_5",
      title: "მწვანე ლობიო",
      category: "ბოსტნეული",
      farmerId: "farmer_1",
      pricePerUnit: 15.0,
      discountPercent: 20,
      unit: "კგ",
      stockQuantity: 60.0,
      stockStatus: "მარაგშია",
      rating: 4.9,
      reviewCount: 70,
      imageUrl: "https://images.unsplash.com/photo-1567375698348-5d9d5ae99de0?w=600&auto=format&fit=crop&q=80",
      description: "ნაზი, უძარღვო მწვანე ლობიო კახეთის ბოსტნებიდან. სწრაფად იხარშება და ინარჩუნებს მკვეთრ ფერსა და სასარგებლო თვისებებს.",
    },
    {
      id: "prod_6",
      title: "კახური შავი ყურძენი",
      category: "ხილი",
      farmerId: "farmer_1",
      pricePerUnit: 25.0,
      discountPercent: 0,
      unit: "კგ",
      stockQuantity: 90.0,
      stockStatus: "მარაგშია",
      rating: 5.0,
      reviewCount: 95,
      imageUrl: "https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=600&auto=format&fit=crop&q=80",
      description: "რჩეული საფერავის ჯიშის სუფრის ყურძენი გურჯაანის ვენახებიდან. ტკბილი, ხორციანი მარცვლებითა და საუკეთესო არომატით.",
    },
    {
      id: "prod_honey_1",
      title: "ალპური ყვავილების თაფლი",
      category: "თაფლი და მეფუტკრეობა",
      farmerId: "farmer_1",
      pricePerUnit: 28.0,
      discountPercent: 0,
      unit: "კგ",
      stockQuantity: 45.0,
      stockStatus: "მარაგშია",
      rating: 5.0,
      reviewCount: 42,
      imageUrl: "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=600&auto=format&fit=crop&q=80",
      description: "100% ნატურალური, გაუცხელებელი ალპური ყვავილის თაფლი მაღალმთიანი რეგიონიდან.",
    },
    {
      id: "prod_wine_1",
      title: "საფერავი ქვევრის (ბიო)",
      category: "მეღვინეობა და სასმელები",
      farmerId: "farmer_3",
      pricePerUnit: 35.0,
      discountPercent: 10,
      unit: "ბოთლი",
      stockQuantity: 150.0,
      stockStatus: "მარაგშია",
      rating: 4.9,
      reviewCount: 56,
      imageUrl: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=600&auto=format&fit=crop&q=80",
      description: "ტრადიციული კახური წესით, ქვევრში 6 თვის განმავლობაში დავარგებული ბიო საფერავი.",
    },
  ];

  for (const p of productsData) {
    await prisma.product.upsert({
      where: { id: p.id },
      update: p,
      create: p,
    });
  }

  // 4. Upsert Sample Orders
  const now = new Date();
  await prisma.order.upsert({
    where: { id: "12345" },
    update: {},
    create: {
      id: "12345",
      clientId: "user_client_1",
      farmerId: "farmer_2",
      status: OrderStatus.COMPLETED,
      totalAmount: 59.0,
      hasVat: true,
      fulfillmentType: FulfillmentType.FARMER_DELIVERY,
      contactPerson: "საბა ევგენიძე",
      contactPhone: "+995 599 12 34 56",
      deliveryTimeWindow: "ივლ 29, 10:00 - 13:00",
      deliveryAddress: "32 ჭავჭავაძე, ბათუმი",
      createdAt: new Date(now.getTime() - 4 * 3600 * 1000),
      items: {
        create: [
          {
            productId: "prod_4",
            quantity: 5,
            pricePerUnit: 10.0,
            subtotal: 50.0,
          },
        ],
      },
      shipment: {
        create: {
          status: ShipmentStatus.CONFIRMED,
          trackingNumber: "AK-12345",
        },
      },
    },
  });

  await prisma.order.upsert({
    where: { id: "12349" },
    update: {},
    create: {
      id: "12349",
      clientId: "user_client_1",
      farmerId: "farmer_1",
      status: OrderStatus.PENDING,
      totalAmount: 84.0,
      hasVat: false,
      fulfillmentType: FulfillmentType.FARMER_DELIVERY,
      contactPerson: "ნინო დავითაშვილი",
      contactPhone: "+995 591 99 88 77",
      deliveryTimeWindow: "დღეს, 18:00 - 20:00",
      deliveryAddress: "ვაჟა-ფშაველას გამზ. 45, თბილისი",
      cancellationDeadline: new Date(now.getTime() + 28 * 60 * 1000),
      items: {
        create: [
          {
            productId: "prod_honey_1",
            quantity: 3,
            pricePerUnit: 28.0,
            subtotal: 84.0,
          },
        ],
      },
      shipment: {
        create: {
          status: ShipmentStatus.PENDING,
          trackingNumber: "AK-12349",
        },
      },
    },
  });

  console.log("✅ Seed completed successfully!");
}

main()
  .catch((e) => {
    console.error("❌ Seed error:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

