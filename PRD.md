# Product Requirements Document (PRD)
> Project: AgroKera — Direct Farm-to-Client Marketplace & Agro-Logistics Platform

## 01 Product Overview
- **Product Name**: AgroKera (აგროკერა)
- **Tagline**: პირდაპირი კავშირი ფერმერსა და მყიდველს შორის — შუამავლების გარეშე.
- **Description**: მობილური პლატფორმა (Flutter), რომელიც აკავშირებს ადგილობრივ ფერმერებს საცალო და B2B კლიენტებთან. არქიტექტურა დაპროექტებულია ჰიბრიდულ მულტი-ტენანტ მოდელზე, რაც უზრუნველყოფს სისტემის უმტკივნეულო გაფართოებას მომდევნო ეტაპებზე (აგრო-მარკეტების ქსელები და დამოუკიდებელი კურიერები).

## 02 Phased Rollout Strategy (ეტაპობრივი განვითარება)

### Phase 1: MVP (მიმდინარე ეტაპი — Flutter App + Core API)
- **აქტიური როლები**: მხოლოდ **ფერმერი (`FARMER`)** და **კლიენტი (`CLIENT`)**.
- **ვერიფიკაცია (KYC)**: ფერმერი რეგისტრაციისას კამერით იღებს პირადობის მოწმობის (ID) ფოტოებს. პროდუქციის გამოქვეყნება იბლოკება ადმინისტრატორის დადასტურებამდე (`VERIFIED`).
- **მიწოდების მეთოდები (კურიერის გარეშე)**:
  1. `FARMER_DELIVERY` — ფერმერის თვითმიწოდება (მითითებულ ქალაქებში/დღეებში).
  2. `SELF_PICKUP` — ადგილზე გატანა ფერმერის მეურნეობიდან/საწყობიდან.

### Phase 2: Scale-Up (არქიტექტურულად მზადაა ბაზაში)
- **`AGRO_MARKET`**: სავაჭრო ქსელების და აგრო-ჰაბების ჩართვა მრავალი ფილიალითა (`Locations`) და ლოკაციაზე მიბმული მარაგებით (`Inventory`).
- **`LOGISTICS_PROVIDER`**: დამოუკიდებელი კურიერების და მულტი-სტოპ მარშრუტების (`Courier_Trips`) გააქტიურება `Shipments` მოდულში.

## 03 Core Features (Phase 1 — Mobile App)
1. **Role-Based Onboarding & KYC**:
   - როლის არჩევა რეგისტრაციისას (ფერმერი / კლიენტი).
   - ფერმერის ID დოკუმენტების გადაღება მხოლოდ პირდაპირი კამერით (Anti-spoofing) და ვერიფიკაციის სტატუსის კონტროლი.
2. **Marketplace & Discovery (Client)**:
   - კატეგორიები (ბოსტნეული, ხილი, რძის პროდუქტები, თაფლი, ღვინო და სხვ.), რეგიონული ფილტრი და ლაივ ძიება.
   - პროდუქტის დეტალური გვერდი: ფასი (კგ/ერთეული), მინიმალური შესაკვეთი რაოდენობა, ფერმერის რეიტინგი და ვერიფიკაციის ბეიჯი.
3. **Farm & Inventory Management (Farmer)**:
   - პროდუქტის დამატება/რედაქტირება, მარაგის (`stock_quantity`) კონტროლი და მიწოდების ზონების/ტარიფების მართვა.
   - Offline-first ქეშირება რეგიონებში არასტაბილური ინტერნეტის დროს მუშაობისთვის.
4. **Order & Fulfillment Tracking**:
   - შეკვეთის (`Order`) და მიწოდების (`Shipment`) გამიჯნული სტატუსები (`PENDING` ➔ `READY_FOR_PICKUP` / `IN_TRANSIT` ➔ `DELIVERED` ➔ `CONFIRMED`).

## 04 Technical Architecture & Stack
- **Mobile Client**: Flutter (Dart) + Riverpod / Bloc + Drift (SQLite offline cache).
- **Backend API & Admin Panel**: Next.js (App Router, TypeScript) / Node.js განთავსებული Render-ზე.
- **Database & ORM**: PostgreSQL (Neon / Supabase) + Prisma ORM (PostGIS მხარდაჭერით).
- **Secure Storage**: Private Cloud Bucket (Signed URLs) ფერმერის ID ფოტოებისთვის.