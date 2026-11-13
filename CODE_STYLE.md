# Code Style & Architecture Guidelines (Flutter)
> Clean Architecture. Feature-First. Offline-Ready.

## 01 General Principles
- **Strict Typing**: აკრძალულია `dynamic` ტიპის გამოყენება, გარდა JSON პარსინგის საწყისი ფენისა (`Map<String, dynamic>`), რომელიც დაუყოვნებლივ გარდაიქმნება მკაცრ Model კლასებად.
- **Feature-First Structure**: კოდი იყოფა ბიზნეს-მოდულების (Features) და არა ტექნიკური ფენების მიხედვით.
- **Single Responsibility**: ერთი ვიჯეტი ასრულებს მხოლოდ ერთ ამოცანას. ეკრანის ფაილი (`*_screen.dart`) არ უნდა აღემატებოდეს 250-300 ხაზს — რთული ბლოკები გაიტანეთ `widgets/` საქაღალდეში.

## 02 Naming Conventions
- **Files & Folders**: `snake_case` (მაგ. `product_card.dart`, `farmer_verification_screen.dart`, `shipment_model.dart`).
- **Classes, Enums & Widgets**: `PascalCase` (მაგ. `ProductCard`, `OrganizationType`, `OrderRepository`).
- **Variables, Methods & Providers**: `camelCase` (მაგ. `fetchFarmerProducts`, `cartTotalProvider`).
- **Constants**: `camelCase` კლასის შიგნით (`AppColors.primary`) ან `UPPER_SNAKE_CASE` გლობალური კონსტანტებისთვის.

## 03 Folder Organization (`lib/`)
```text
lib/
├── core/
│   ├── constants/        # API endpoints, storage keys, enums
│   ├── network/          # Dio client, Auth interceptors, offline queue
│   ├── storage/          # Drift/SQLite local DB & SecureStorage
│   ├── theme/            # app_colors.dart, app_typography.dart, app_theme.dart
│   └── widgets/          # საერთო UI კომპონენტები (PrimaryButton, CustomTextField, StatusBadge)
├── features/
│   ├── auth/             # რეგისტრაცია, ავტორიზაცია, როლის არჩევა (Farmer / Client)
│   ├── verification/     # ფერმერის ID კამერით გადაღება და სტატუსის შემოწმება
│   ├── marketplace/      # კატალოგი, ძიება, ფილტრები, პროდუქტის დეტალები
│   ├── farm_inventory/   # ფერმერის პროდუქტების დამატება, მარაგების და მიწოდების ზონების მართვა
│   ├── cart_checkout/    # კალათა, მიწოდების მეთოდის არჩევა (Farmer Delivery / Self Pickup)
│   ├── orders/           # შეკვეთები (Order) და მიწოდების სტატუსები (Shipment)
│   └── profile/          # ორგანიზაციის პროფილი, ლოკაციები (Locations), პარამეტრები
└── main.dart