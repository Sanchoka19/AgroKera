import React from "react";
import type { VerificationStatus } from "../../types/index.ts";

export interface BadgeProps {
  children?: React.ReactNode;
  variant?:
    | "success"
    | "warning"
    | "danger"
    | "info"
    | "neutral"
    | "teal";
  status?: VerificationStatus | string;
  size?: "sm" | "md";
  className?: string;
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  variant,
  status,
  size = "md",
  className = "",
}) => {
  let resolvedVariant = variant || "neutral";
  let text = children;

  if (status) {
    switch (status) {
      case "VERIFIED":
        resolvedVariant = "teal";
        text = text || "ვერიფიცირებული";
        break;
      case "PENDING_REVIEW":
        resolvedVariant = "warning";
        text = text || "მოლოდინში";
        break;
      case "REJECTED":
        resolvedVariant = "danger";
        text = text || "დახარვეზებული";
        break;
      case "UNVERIFIED":
        resolvedVariant = "neutral";
        text = text || "არავერიფიცირებული";
        break;
      case "COMPLETED":
        resolvedVariant = "success";
        text = text || "დასრულებული";
        break;
      case "IN_PROGRESS":
        resolvedVariant = "info";
        text = text || "პროცესშია";
        break;
      case "CONFIRMED":
        resolvedVariant = "teal";
        text = text || "დადასტურებული";
        break;
      case "CANCELLED":
        resolvedVariant = "danger";
        text = text || "გაუქმებული";
        break;
    }
  }

  const variantStyles = {
    success: "bg-emerald-50 text-emerald-700 border-emerald-200",
    warning: "bg-amber-50 text-amber-800 border-amber-200",
    danger: "bg-rose-50 text-rose-700 border-rose-200",
    info: "bg-sky-50 text-sky-700 border-sky-200",
    neutral: "bg-slate-100 text-slate-700 border-slate-200",
    teal: "bg-teal-50 text-teal-800 border-teal-200",
  };

  const sizeStyles = {
    sm: "px-2 py-0.5 text-xs font-semibold",
    md: "px-2.5 py-1 text-xs font-semibold",
  };

  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border ${variantStyles[resolvedVariant]} ${sizeStyles[size]} ${className}`}
    >
      <span
        className={`w-1.5 h-1.5 rounded-full ${
          resolvedVariant === "teal"
            ? "bg-teal-600"
            : resolvedVariant === "success"
            ? "bg-emerald-600"
            : resolvedVariant === "warning"
            ? "bg-amber-600"
            : resolvedVariant === "danger"
            ? "bg-rose-600"
            : "bg-slate-400"
        }`}
      />
      {text}
    </span>
  );
};

