import React from "react";
import { Search } from "lucide-react";

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  icon?: React.ReactNode;
}

export const Input: React.FC<InputProps> = ({
  label,
  error,
  icon,
  className = "",
  id,
  ...props
}) => {
  const inputId = id || (label ? label.toLowerCase().replace(/\s+/g, "-") : undefined);

  return (
    <div className="w-full">
      {label ? (
        <label
          htmlFor={inputId}
          className="block text-xs font-semibold text-slate-700 mb-1.5"
        >
          {label}
        </label>
      ) : null}
      <div className="relative flex items-center">
        {icon ? (
          <div className="absolute left-3 text-slate-400 pointer-events-none">
            {icon}
          </div>
        ) : null}
        <input
          id={inputId}
          className={`w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-teal-600 focus:outline-none focus:ring-1 focus:ring-teal-600 transition-colors disabled:bg-slate-50 disabled:text-slate-500 ${
            icon ? "pl-9" : ""
          } ${error ? "border-rose-500 focus:border-rose-500 focus:ring-rose-500" : ""} ${className}`}
          {...props}
        />
      </div>
      {error ? <p className="mt-1 text-xs text-rose-600">{error}</p> : null}
    </div>
  );
};

export const SearchInput: React.FC<Omit<InputProps, "icon">> = (props) => {
  return <Input icon={<Search className="w-4 h-4" />} {...props} />;
};

