import React from "react";
import { UserCheck, Menu } from "lucide-react";
import type { AdminUser } from "../../types/index.ts";

interface HeaderProps {
  title: string;
  subtitle?: string;
  admin: AdminUser | null;
  actions?: React.ReactNode;
  onOpenMobileMenu?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  subtitle,
  admin,
  actions,
  onOpenMobileMenu,
}) => {
  return (
    <header className="h-16 bg-white border-b border-slate-200 px-4 sm:px-6 lg:px-8 flex items-center justify-between shrink-0">
      <div className="flex items-center gap-3 min-w-0">
        {/* Mobile Hamburger Menu Button */}
        <button
          type="button"
          onClick={onOpenMobileMenu}
          className="lg:hidden p-2 -ml-1 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors"
          aria-label="მენიუს გახსნა"
        >
          <Menu className="w-5 h-5" />
        </button>

        <div className="min-w-0">
          <h1 className="text-base sm:text-lg font-black text-slate-900 tracking-tight truncate">
            {title}
          </h1>
          {subtitle ? (
            <p className="hidden sm:block text-xs text-slate-500 font-medium truncate">
              {subtitle}
            </p>
          ) : null}
        </div>
      </div>

      <div className="flex items-center gap-3 sm:gap-4 shrink-0">
        {actions ? <div>{actions}</div> : null}

        {admin ? (
          <div className="flex items-center gap-2 bg-slate-50 border border-slate-200 px-2.5 sm:px-3 py-1.5 rounded-full">
            <div className="w-6 h-6 rounded-full bg-teal-100 text-teal-800 flex items-center justify-center shrink-0">
              <UserCheck className="w-3.5 h-3.5" />
            </div>
            <div className="text-xs">
              <span className="font-bold text-slate-800 hidden md:inline">
                {admin.fullName || "ადმინისტრატორი"}
              </span>
              <span className="text-[10px] text-teal-700 bg-teal-50 md:ml-1.5 px-1.5 py-0.5 rounded font-black uppercase">
                {admin.role}
              </span>
            </div>
          </div>
        ) : null}
      </div>
    </header>
  );
};

