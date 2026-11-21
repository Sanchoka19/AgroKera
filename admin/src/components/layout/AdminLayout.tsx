import React from "react";
import { Sidebar, type NavTab } from "./Sidebar.tsx";
import { Header } from "./Header.tsx";
import type { AdminUser } from "../../types/index.ts";

interface AdminLayoutProps {
  currentTab: NavTab;
  onSelectTab: (tab: NavTab) => void;
  admin: AdminUser | null;
  pendingKycCount?: number;
  onLogout: () => void;
  title: string;
  subtitle?: string;
  headerActions?: React.ReactNode;
  children: React.ReactNode;
}

export const AdminLayout: React.FC<AdminLayoutProps> = ({
  currentTab,
  onSelectTab,
  admin,
  pendingKycCount,
  onLogout,
  title,
  subtitle,
  headerActions,
  children,
}) => {
  return (
    <div className="flex h-screen bg-slate-50 overflow-hidden font-['Noto_Sans_Georgian',sans-serif]">
      <Sidebar
        currentTab={currentTab}
        onSelectTab={onSelectTab}
        pendingKycCount={pendingKycCount}
        onLogout={onLogout}
      />
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Header
          title={title}
          subtitle={subtitle}
          admin={admin}
          actions={headerActions}
        />
        <main className="flex-1 overflow-y-auto p-8">{children}</main>
      </div>
    </div>
  );
};

