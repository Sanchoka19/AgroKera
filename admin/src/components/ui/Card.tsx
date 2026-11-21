import React from "react";

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  className?: string;
}

export const Card: React.FC<CardProps> = ({
  children,
  className = "",
  ...props
}) => {
  return (
    <div
      className={`bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

export const CardHeader: React.FC<{
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
  className?: string;
}> = ({ title, subtitle, action, className = "" }) => {
  return (
    <div
      className={`px-5 py-4 border-b border-slate-100 flex items-center justify-between ${className}`}
    >
      <div>
        <h3 className="font-bold text-slate-900 text-base">{title}</h3>
        {subtitle ? (
          <p className="text-xs text-slate-500 mt-0.5">{subtitle}</p>
        ) : null}
      </div>
      {action ? <div>{action}</div> : null}
    </div>
  );
};

export const CardBody: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className = "" }) => {
  return <div className={`p-5 ${className}`}>{children}</div>;
};

