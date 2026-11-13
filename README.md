# AgroKera (აგროკერა) 🌱

**AgroKera** is a direct farm-to-client mobile marketplace and agro-logistics platform built with **Flutter**, backed by a scalable multi-tenant **PostgreSQL + Prisma** architecture.

---

## ✨ Core Features (Phase 1 MVP)

- **👨‍🌾 Farmer & Client Roles**: Unified mobile app with dedicated workflows for farmers (inventory & delivery management) and buyers (discovery & ordering).
- **🪪 Camera-Only Farmer KYC**: Mandatory ID document capture directly from the device camera, reviewed and approved via the Admin Panel before listing products.
- **🚚 Flexible Fulfillment (Phase 1)**:
  - **Farmer Delivery**: Scheduled regional deliveries managed by the farmer.
  - **Self Pickup**: Direct farm-gate pickup with GPS coordinates and time windows.
- **📡 Offline-First Ready**: Local SQLite caching (`Drift`) ensuring uninterrupted farm inventory updates in low-connectivity rural areas.
- **🏗️ Future-Proof Architecture**: Database and API schema pre-structured for **Agro-Markets** (multi-branch retail chains) and **Third-Party Couriers** (multi-stop route consolidation).

---

## 🎨 Design System

- **Primary Brand Color**: `#53B175` (Organic Green)
- **Background**: `#F8FAFC` / Surface `#FFFFFF`
- **Typography & Contrast**: `#181725` Primary Text, `#F3603F` Warm Harvest Accents
- Built directly from custom **Figma** designs using centralized theme tokens (`lib/core/theme/`).

---

## 🛠️ Tech Stack

- **Mobile App**: Flutter (Dart), Riverpod, GoRouter, Dio, Drift (SQLite)
- **Backend & Admin Panel**: Next.js (App Router, TypeScript) / Node.js on Render
- **Database**: PostgreSQL (Neon / Supabase) + Prisma ORM + PostGIS
- **Storage**: Private Cloud Storage (Signed URLs for KYC ID documents)

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `3.24.x` or higher
- **Dart SDK**: `3.5.x` or higher

### 1. Install Dependencies
```bash
flutter pub get

2. Configure Environment

Create a .env file in the root directory:
კოდის ნაწყვეტი

API_BASE_URL=[https://api.agrokera.ge/v1](https://api.agrokera.ge/v1)
GOOGLE_MAPS_API_KEY=your_maps_key_here

3. Run the App
Bash

flutter run

📁 Project Structure
Plaintext

agrokera_app/
├── lib/
│   ├── core/             # Theme (#53B175), network client, offline DB, shared widgets
│   ├── features/         # Feature-first modules (auth, verification, marketplace, orders)
│   └── main.dart         # App entry point
├── test/                 # Unit & widget tests
├── PRD.md                # Product requirements & phased roadmap
├── DESIGN_SYSTEM.md      # Color palette, typography & Figma implementation rules
├── CODE_STYLE.md         # Flutter architecture & coding standards
└── TESTING.md            # Testing strategy & QA checklist
