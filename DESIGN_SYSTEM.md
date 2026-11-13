# Design System — AgroKera
> Fresh, Trustworthy & Clean Agro-Marketplace Experience (60-30-10 Rule)
> Single Source of Truth (SSOT): `lib/core/theme/app_colors.dart` & `app_theme.dart`

## 01 Brand Identity & Figma Workflow
- **Mood**: სუფთა, ბუნებრივი, სანდო და თანამედროვე მობილური გამოცდილება.
- **Theme Mode**: Light-Mode First (მაღალი კონტრასტი ღია ცის ქვეშ / საველე პირობებში მუშაობისთვის).
- **Figma Screenshot-to-Code Protocol**:
  - ყველა ეკრანი იგება მოწოდებული Figma სქრინშოთების მიხედვით.
  - სქრინშოთიდან კოდის გენერირებისას აკრძალულია Hardcoded ფერების (`Color(0xFF...)`) ან ზომების ჩაწერა პირდაპირ ვიჯეტებში — ყოველი ფერი უნდა მიებას `AppColors`-ს, ხოლო ტექსტი `AppTypography`-ს.

## 02 Color Palette (60-30-10 Rule)

### 60% MAIN (Dominant Base & Surfaces)
- **Background Primary**: `#F8FAFC` (`AppColors.bgPrimary` — მთავარი ეკრანის ფონი)
- **Surface / Cards**: `#FFFFFF` (`AppColors.surface` — პროდუქტის ბარათები, მოდალები, კალათა)
- **Surface Subtle / Input Fill**: `#F2F3F2` (`AppColors.surfaceInput` — ძებნის ველი და ინფუთები)
- **Border / Divider**: `#E2E2E2` (`AppColors.border`)

### 30% SECOND (Structure, Typography & Soft Organic Tints)
- **Text Primary (Headings & Titles)**: `#181725` (`AppColors.textPrimary` — ღრმა ნახშირისფერი, მაღალი წაკითხვადობა)
- **Text Secondary / Muted**: `#7C7C7C` (`AppColors.textSecondary` — აღწერები, წონა, ლოკაცია)
- **Soft Leaf Tint (Secondary Badges & Containers)**: `#EBF7EF` (`AppColors.primaryLight` — კატეგორიის ფონები, აქტიური ფილტრები)
- **Verification / Trust Blue**: `#2D9CDB` (`AppColors.info` — „ვერიფიცირებული ფერმერის“ ნიშანი)

### 10% ACCENT (Primary Brand Color & Calls to Action)
- **Primary Brand Green**: `#53B175` (`AppColors.primary` — მთავარი ღილაკები, აქტიური ტაბები, ფასები)
- **Primary Pressed / Hover**: `#439660` (`AppColors.primaryDark`)
- **Text on Primary**: `#FFFFFF` (`AppColors.textOnPrimary`)
- **Warm Harvest Accent (Alerts / Discounts / Urgency)**: `#F3603F` (`AppColors.accentWarm` — ფასდაკლების ბეიჯი, მცირე მარაგის გაფრთხილება, შეკვეთის გაუქმება)
- **Star Rating / Amber**: `#F3A938` (`AppColors.rating`)

## 03 Typography (`Gilroy` / `Inter` / `Noto Sans Georgian`)
- **Display / Screen Title**: `24px`, `FontWeight.w700` (`AppTypography.h1`)
- **Section Header**: `18px`, `FontWeight.w700` (`AppTypography.h2`)
- **Card Title / Product Name**: `16px`, `FontWeight.w600` (`AppTypography.titleMedium`)
- **Body / Description**: `14px`, `FontWeight.w400` (`AppTypography.bodyMedium`)
- **Caption / Unit / Badge**: `12px`, `FontWeight.w500` (`AppTypography.caption`)

## 04 Core UI Components Spec
- **Buttons**: `BorderRadius.circular(16)`, სიმაღლე `52px` (Primary CTA: `#53B175`, თეთრი ტექსტი).
- **Product Card**: თეთრი ფონი (`#FFFFFF`), `1px` ბორდერი (`#E2E2E2`), `BorderRadius.circular(18)`, ზედა ნაწილში პროდუქტის ფოტო, ქვემოთ სათაური, ერთეული (`1 კგ`), ფასი და `+` სწრაფი დამატების ღილაკი (`#53B175`).
- **Inputs**: შევსებული ფონი (`#F2F3F2`), `BorderRadius.circular(14)`, ფოკუსისას `1.5px` `#53B175` ბორდერი.
- **Icons**: `lucide_icons_flutter` ან `iconsax` (სუფთა, მომრგვალებული ხაზოვანი აიქონები).