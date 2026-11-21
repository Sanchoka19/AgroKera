import React from "react";

export interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  trend?: string;
  variant?: "default" | "teal" | "amber" | "rose";
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  trend,
  variant = "default",
}) => {
  const iconBgStyles = {
    default: "bg-slate-100 text-slate-700",
    teal: "bg-teal-50 text-teal-700",
    amber: "bg-amber-50 text-amber-700",
    rose: "bg-rose-50 text-rose-700",
  };

  return (
    <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex items-start justify-between">
      <div>
        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
          {title}
        </p>
        <p className="text-2xl font-black text-slate-900 mt-1">{value}</p>
        {subtitle ? (
          <p className="text-xs text-slate-500 mt-1">{subtitle}</p>
        ) : null}
        {trend ? (
          <span className="inline-block mt-2 text-xs font-bold text-teal-700 bg-teal-50 px-2 py-0.5 rounded-md">
            {trend}
          </span>
        ) : null}
      </div>
      <div className={`p-3 rounded-xl ${iconBgStyles[variant]}`}>{icon}</div>
    </div>
  );
};

