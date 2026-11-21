import React from "react";
import { AlertTriangle, CheckCircle2, X } from "lucide-react";
import { Button } from "./Button.tsx";

export interface ConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void | Promise<void>;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  variant?: "primary" | "danger" | "warning";
  isLoading?: boolean;
  icon?: React.ReactNode;
}

export const ConfirmationModal: React.FC<ConfirmationModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = "დადასტურება",
  cancelText = "გაუქმება",
  variant = "primary",
  isLoading = false,
  icon,
}) => {
  if (!isOpen) return null;

  const variantStyles = {
    primary: {
      iconBg: "bg-teal-50 text-teal-600 border-teal-200",
      defaultIcon: <CheckCircle2 className="w-6 h-6" />,
      btnVariant: "primary" as const,
    },
    danger: {
      iconBg: "bg-rose-50 text-rose-600 border-rose-200",
      defaultIcon: <AlertTriangle className="w-6 h-6" />,
      btnVariant: "danger" as const,
    },
    warning: {
      iconBg: "bg-amber-50 text-amber-600 border-amber-200",
      defaultIcon: <AlertTriangle className="w-6 h-6" />,
      btnVariant: "primary" as const,
    },
  };

  const currentVariant = variantStyles[variant];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity animate-in fade-in-0 duration-150"
        onClick={!isLoading ? onClose : undefined}
      />

      {/* Modal Dialog */}
      <div className="relative z-10 w-full max-w-md rounded-2xl bg-white shadow-2xl border border-slate-100 overflow-hidden transform transition-all animate-in fade-in-0 zoom-in-95 duration-150 p-6">
        <div className="flex items-start gap-4">
          <div
            className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 border ${currentVariant.iconBg}`}
          >
            {icon || currentVariant.defaultIcon}
          </div>

          <div className="flex-1 min-w-0 pt-0.5">
            <h3 className="text-base font-bold text-slate-900 leading-snug">
              {title}
            </h3>
            <p className="text-xs text-slate-500 mt-1.5 leading-relaxed">
              {message}
            </p>
          </div>

          {!isLoading ? (
            <button
              onClick={onClose}
              className="rounded-lg p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors -mr-1 -mt-1"
            >
              <X className="w-4 h-4" />
            </button>
          ) : null}
        </div>

        <div className="flex items-center justify-end gap-3 mt-6 pt-4 border-t border-slate-100">
          <Button
            variant="outline"
            size="sm"
            onClick={onClose}
            disabled={isLoading}
          >
            {cancelText}
          </Button>
          <Button
            variant={currentVariant.btnVariant}
            size="sm"
            onClick={onConfirm}
            isLoading={isLoading}
          >
            {confirmText}
          </Button>
        </div>
      </div>
    </div>
  );
};
