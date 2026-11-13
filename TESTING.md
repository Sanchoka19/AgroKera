# Testing Strategy & Quality Assurance
> Reliable Agro-Commerce. Accurate Inventory & Verification.

## 01 Testing Philosophy
ტესტირების მთავარი პრიორიტეტებია:
1. მარაგების (`stock_quantity`) ზუსტი კალკულაცია და შეკვეთის ჯამური ღირებულების გამოთვლა.
2. ფერმერის ვერიფიკაციის (`UNVERIFIED` ➔ `PENDING_REVIEW` ➔ `VERIFIED`) წვდომის კონტროლი.
3. Offline-First ქეშის სინქრონიზაცია ქსელის აღდგენისას.

## 02 Testing Stack
- **Unit & Widget Tests**: `flutter_test`
- **Mocking**: `mocktail` (Repository-ებისა და API სერვისების იზოლირებული ტესტირებისთვის)
- **Integration / E2E Tests**: `integration_test`

## 03 Test Coverage Areas

### 1. Unit Tests (`test/unit/`)
- **Cart & Pricing Calculator**: ამოწმებს პროდუქტების ჯამს, ფერმერის მიტანის ტარიფის დამატებას (`FARMER_DELIVERY`) და უფასო მიწოდების ზღვარს (`SELF_PICKUP` = `0.00`).
- **Model Serialization**: ამოწმებს `Order` და `Shipment` JSON-ის პარსინგს და მომავალი ველების (`carrierId`, `agroMarketLocationId`) უსაფრთხო `null` დამუშავებას.
- **Verification Gate Logic**: ამოწმებს, რომ არავერიფიცირებულ ფერმერს ეზღუდება პროდუქტის გამოქვეყნება.

### 2. Widget Tests (`test/widgets/`)
- **`ProductCard`**: ამოწმებს პროდუქტის სახელის, ერთეულის, ფასის (`#53B175`) და `+` ღილაკზე დაჭერის ქცევას.
- **`CheckoutFulfillmentSelector`**: ამოწმებს გადართვას „ფერმერის მიტანასა“ და „ადგილზე გატანას“ შორის.
- **`VerificationUploadCard`**: ამოწმებს ID დოკუმენტის წინა და უკანა მხარის ატვირთვის სტატუსებს.

## 04 Commands & Pre-Commit Checklist
```bash
# Run all unit and widget tests
flutter test

# Static code analysis
flutter analyze

# Code formatting check
dart format --output=none --set-exit-if-changed .

[ ] flutter analyze არ აბრუნებს გაფრთხილებებს (Warnings/Errors).

[ ] ყველა Unit და Widget ტესტი წარმატებით გადის (flutter test).

[ ] UI კომპონენტები იყენებენ მხოლოდ AppColors ტოკენებს (#53B175 პალიტრიდან).