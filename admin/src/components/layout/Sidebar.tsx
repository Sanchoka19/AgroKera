import React from "react";
import {
  LayoutDashboard,
  ShieldCheck,
  Users,
  Package,
  ShoppingCart,
  CreditCard,
  LogOut,
} from "lucide-react";
import { AgroKeraLogo } from "../ui/AgroKeraLogo.tsx";

export type NavTab =
  | "dashboard"
  | "kyc"
  | "farmers"
  | "products"
  | "orders"
  | "payouts";

interface SidebarProps {
  currentTab: NavTab;
  onSelectTab: (tab: NavTab) => void;
  pendingKycCount?: number;
  onLogout: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  pendingKycCount = 0,
  onLogout,
}) => {
  const navItems: Array<{
    id: NavTab;
    label: string;
    icon: React.ReactNode;
    badge?: number;
  }> = [
    {
      id: "dashboard",
      label: "დაშბორდი",
      icon: <LayoutDashboard className="w-5 h-5 shrink-0" />,
    },
    {
      id: "kyc",
      label: "KYC ვერიფიკაცია",
      icon: <ShieldCheck className="w-5 h-5 shrink-0" />,
      badge: pendingKycCount > 0 ? pendingKycCount : undefined,
    },
    {
      id: "farmers",
      label: "ფერმერები",
      icon: <Users className="w-5 h-5 shrink-0" />,
    },
    {
      id: "products",
      label: "პროდუქცია",
      icon: <Package className="w-5 h-5 shrink-0" />,
    },
    {
      id: "orders",
      label: "შეკვეთები",
      icon: <ShoppingCart className="w-5 h-5 shrink-0" />,
    },
    {
      id: "payouts",
      label: "ფინანსები და Payout",
      icon: <CreditCard className="w-5 h-5 shrink-0" />,
    },
  ];

  return (
    <aside className="w-68 bg-slate-900 text-white flex flex-col shrink-0 min-h-screen border-r border-slate-800">
      {/* Brand Header */}
      <div className="h-16 px-6 flex items-center border-b border-slate-800/80 bg-slate-950/40">
        <AgroKeraLogo size={32} />
      </div>

      {/* Navigation Links */}
      <nav className="p-3.5 space-y-1.5 flex-1">
        <div className="text-[11px] font-bold text-slate-400 uppercase tracking-wider px-3 mb-2 text-left">
          მართვის მოდულები
        </div>
        {navItems.map((item) => {
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onSelectTab(item.id)}
              className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-semibold text-left transition-all ${
                isActive
                  ? "bg-teal-700 text-white shadow-md shadow-teal-900/30"
                  : "text-slate-300 hover:bg-slate-800 hover:text-white"
              }`}
            >
              <div className="flex items-center gap-3 min-w-0">
                <span className={`shrink-0 ${isActive ? "text-white" : "text-slate-400"}`}>
                  {item.icon}
                </span>
                <span className="whitespace-nowrap truncate text-left">
                  {item.label}
                </span>
              </div>
              {item.badge ? (
                <span className="bg-amber-500 text-slate-950 text-xs font-black px-2 py-0.5 rounded-full shadow-xs shrink-0 ml-2 animate-pulse">
                  {item.badge}
                </span>
              ) : null}
            </button>
          );
        })}
      </nav>

      {/* Footer / Logout */}
      <div className="p-3.5 border-t border-slate-800/80">
        <button
          onClick={onLogout}
          className="w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-semibold text-left text-rose-300 hover:bg-rose-950/40 hover:text-rose-200 transition-colors"
        >
          <LogOut className="w-5 h-5 shrink-0 text-rose-400" />
          <span className="whitespace-nowrap text-left">ადმინიდან გამოსვლა</span>
        </button>
      </div>
    </aside>
  );
};

