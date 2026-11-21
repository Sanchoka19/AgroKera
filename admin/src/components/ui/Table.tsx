import React from "react";

export const Table: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className = "" }) => {
  return (
    <div className="w-full overflow-x-auto">
      <table className={`w-full text-left text-sm ${className}`}>
        {children}
      </table>
    </div>
  );
};

export const TableHead: React.FC<{
  children: React.ReactNode;
}> = ({ children }) => {
  return (
    <thead className="bg-slate-50 border-b border-slate-200 text-xs font-bold text-slate-500 uppercase tracking-wider">
      {children}
    </thead>
  );
};

export const TableBody: React.FC<{
  children: React.ReactNode;
}> = ({ children }) => {
  return <tbody className="divide-y divide-slate-100">{children}</tbody>;
};

export const TableRow: React.FC<{
  children: React.ReactNode;
  className?: string;
  onClick?: () => void;
}> = ({ children, className = "", onClick }) => {
  return (
    <tr
      onClick={onClick}
      className={`hover:bg-slate-50/80 transition-colors ${
        onClick ? "cursor-pointer" : ""
      } ${className}`}
    >
      {children}
    </tr>
  );
};

export const TableCell: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className = "" }) => {
  return <td className={`px-4 py-3.5 text-slate-700 ${className}`}>{children}</td>;
};

export const TableHeaderCell: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className = "" }) => {
  return (
    <th className={`px-4 py-3 text-slate-500 font-bold ${className}`}>
      {children}
    </th>
  );
};

export const EmptyState: React.FC<{
  title: string;
  subtitle?: string;
  icon?: React.ReactNode;
  action?: React.ReactNode;
}> = ({ title, subtitle, icon, action }) => {
  return (
    <div className="py-12 flex flex-col items-center justify-center text-center px-4">
      {icon ? <div className="text-slate-400 mb-3">{icon}</div> : null}
      <h4 className="text-sm font-bold text-slate-800">{title}</h4>
      {subtitle ? (
        <p className="text-xs text-slate-500 max-w-sm mt-1 mb-4">{subtitle}</p>
      ) : null}
      {action ? <div>{action}</div> : null}
    </div>
  );
};

