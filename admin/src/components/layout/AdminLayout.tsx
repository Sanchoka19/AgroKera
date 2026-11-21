import React, { useState } from "react";
import { Sidebar, type NavTab } from "./Sidebar.tsx";
import { Header } from "./Header.tsx";
import { ConfirmationModal } from "../ui/ConfirmationModal.tsx";
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
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  return (
    <div className="flex h-screen bg-slate-50 overflow-hidden font-['Noto_Sans_Georgian',sans-serif]">
      <Sidebar
        currentTab={currentTab}
        onSelectTab={onSelectTab}
        pendingKycCount={pendingKycCount}
        onLogout={() => setShowLogoutConfirm(true)}
        isMobileOpen={mobileMenuOpen}
        onCloseMobile={() => setMobileMenuOpen(false)}
      />
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Header
          title={title}
          subtitle={subtitle}
          admin={admin}
          actions={headerActions}
          onOpenMobileMenu={() => setMobileMenuOpen(true)}
        />
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          <div className="max-w-7xl mx-auto">{children}</div>
        </main>
      </div>

      {/* Reusable Logout Confirmation Dialog */}
      <ConfirmationModal
        isOpen={showLogoutConfirm}
        onClose={() => setShowLogoutConfirm(false)}
        onConfirm={onLogout}
        title="ადმინიდან გამოსვლა"
        message="ნამდვილად გსურთ ადმინისტრატორის მართვის პანელიდან გამოსვლა? სესიის გასაგრძელებლად საჭირო იქნება ხელახალი ავტორიზაცია."
        confirmText="გამოსვლა"
        cancelText="დარჩენა"
        variant="danger"
      />
    </div>
  );
};

