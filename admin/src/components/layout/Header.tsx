import React from "react";
import { UserCheck } from "lucide-react";
import type { AdminUser } from "../../types/index.ts";

interface HeaderProps {
  title: string;
  subtitle?: string;
  admin: AdminUser | null;
  actions?: React.ReactNode;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  subtitle,
  admin,
  actions,
}) => {
  return (
    <header className="h-16 bg-white border-b border-slate-200 px-8 flex items-center justify-between shrink-0">
      <div>
        <h1 className="text-lg font-black text-slate-900 tracking-tight">
          {title}
        </h1>
        {subtitle ? (
          <p className="text-xs text-slate-500 font-medium">{subtitle}</p>
        ) : null}
      </div>

      <div className="flex items-center gap-4">
        {actions ? <div>{actions}</div> : null}

        {admin ? (
          <div className="flex items-center gap-2.5 bg-slate-50 border border-slate-200 px-3 py-1.5 rounded-full">
            <div className="w-6 h-6 rounded-full bg-teal-100 text-teal-800 flex items-center justify-center">
              <UserCheck className="w-3.5 h-3.5" />
            </div>
            <div className="text-xs">
              <span className="font-bold text-slate-800">
                {admin.fullName || "ადმინისტრატორი"}
              </span>
              <span className="text-[10px] text-teal-700 bg-teal-50 ml-1.5 px-1 py-0.5 rounded font-black">
                {admin.role}
              </span>
            </div>
          </div>
        ) : null}
      </div>
    </header>
  );
};

