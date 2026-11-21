import React, { useState } from "react";
import { useAdminAuth } from "./hooks/useAdminAuth.ts";
import { useDashboardStats } from "./hooks/useDashboardStats.ts";
import { AdminLayout } from "./components/layout/AdminLayout.tsx";
import type { NavTab } from "./components/layout/Sidebar.tsx";

import { LoginView } from "./features/auth/LoginView.tsx";
import { DashboardView } from "./features/dashboard/DashboardView.tsx";
import { KycQueueView } from "./features/kyc/KycQueueView.tsx";
import { FarmersView } from "./features/farmers/FarmersView.tsx";
import { ProductsView } from "./features/products/ProductsView.tsx";
import { OrdersView } from "./features/orders/OrdersView.tsx";
import { PayoutsView } from "./features/payouts/PayoutsView.tsx";

export const App: React.FC = () => {
  const { admin, isAuthenticated, isLoading, error, login, logout } =
    useAdminAuth();
  const [currentTab, setCurrentTab] = useState<NavTab>("dashboard");
  const { kpis } = useDashboardStats();

  if (!isAuthenticated) {
    return (
      <LoginView
        onLogin={login}
        isLoading={isLoading}
        error={error}
      />
    );
  }

  const tabTitles: Record<NavTab, { title: string; subtitle: string }> = {
    dashboard: {
      title: "მთავარი დაშბორდი",
      subtitle: "AgroKera-ს რეალურ დროში მონიტორინგი და მაჩვენებლები",
    },
    kyc: {
      title: "KYC ვერიფიკაციის რიგი",
      subtitle: "ფერმერთა პირადობის მოწმობების გადამოწმება და დადასტურება",
    },
    farmers: {
      title: "ფერმერების რეესტრი",
      subtitle: "რეგისტრირებული მეურნეობები, რეიტინგები და სტატისტიკა",
    },
    products: {
      title: "პროდუქციის კატალოგი",
      subtitle: "მარკეტფლეისზე არსებული მოსავლის მოდერაცია და მარაგები",
    },
    orders: {
      title: "შეკვეთები და ლოგისტიკა",
      subtitle: "მყიდველებისა და ფერმერების აქტიური და დასრულებული შეკვეთები",
    },
    payouts: {
      title: "ფინანსები და საბანკო Payout",
      subtitle: "ფერმერებისთვის გადასარიცხი თანხების რეესტრი (BOG / TBC)",
    },
  };

  return (
    <AdminLayout
      currentTab={currentTab}
      onSelectTab={setCurrentTab}
      admin={admin}
      pendingKycCount={kpis?.pendingKycCount}
      onLogout={logout}
      title={tabTitles[currentTab].title}
      subtitle={tabTitles[currentTab].subtitle}
    >
      {currentTab === "dashboard" && (
        <DashboardView onNavigate={setCurrentTab} />
      )}
      {currentTab === "kyc" && <KycQueueView />}
      {currentTab === "farmers" && <FarmersView />}
      {currentTab === "products" && <ProductsView />}
      {currentTab === "orders" && <OrdersView />}
      {currentTab === "payouts" && <PayoutsView />}
    </AdminLayout>
  );
};

export default App;

