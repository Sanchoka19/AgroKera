import React, { useState } from "react";
import { Lock, Mail, KeyRound, AlertCircle } from "lucide-react";
import { AgroKeraLogo } from "../../components/ui/AgroKeraLogo.tsx";
import { Button } from "../../components/ui/Button.tsx";
import { Input } from "../../components/ui/Input.tsx";

interface LoginViewProps {
  onLogin: (credentials: {
    email?: string;
    password?: string;
    adminKey?: string;
  }) => Promise<boolean>;
  isLoading: boolean;
  error: string | null;
}

export const LoginView: React.FC<LoginViewProps> = ({
  onLogin,
  isLoading,
  error,
}) => {
  const [loginMode, setLoginMode] = useState<"credentials" | "key">("credentials");
  const [email, setEmail] = useState("admin@agrokera.ge");
  const [password, setPassword] = useState("");
  const [adminKey, setAdminKey] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (loginMode === "credentials") {
      await onLogin({ email, password });
    } else {
      await onLogin({ adminKey });
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-2xl border border-slate-100 p-8">
        <div className="flex flex-col items-center text-center mb-8">
          <AgroKeraLogo size={42} showText={false} />
          <h2 className="text-xl font-black text-slate-900 mt-4 tracking-tight">
            AgroKera ადმინ პანელი
          </h2>
          <p className="text-xs text-slate-500 mt-1">
            შეიყვანეთ ადმინისტრატორის ავტორიზაციის მონაცემები
          </p>
        </div>

        {error ? (
          <div className="mb-6 bg-rose-50 border border-rose-200 rounded-xl p-3.5 flex items-start gap-3 text-rose-700 text-xs font-semibold">
            <AlertCircle className="w-4 h-4 shrink-0 text-rose-500 mt-0.5" />
            <span>{error}</span>
          </div>
        ) : null}

        {/* Mode Selector */}
        <div className="flex rounded-lg bg-slate-100 p-1 mb-6 text-xs font-bold text-slate-600">
          <button
            type="button"
            onClick={() => setLoginMode("credentials")}
            className={`flex-1 py-1.5 rounded-md transition-all ${
              loginMode === "credentials"
                ? "bg-white text-slate-900 shadow-xs"
                : "hover:text-slate-900"
            }`}
          >
            ელ-ფოსტა / პაროლი
          </button>
          <button
            type="button"
            onClick={() => setLoginMode("key")}
            className={`flex-1 py-1.5 rounded-md transition-all ${
              loginMode === "key"
                ? "bg-white text-slate-900 shadow-xs"
                : "hover:text-slate-900"
            }`}
          >
            Admin Secret Key
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {loginMode === "credentials" ? (
            <>
              <Input
                label="ადმინის ელ-ფოსტა"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                icon={<Mail className="w-4 h-4 text-slate-400" />}
                required
              />
              <Input
                label="პაროლი"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                icon={<Lock className="w-4 h-4 text-slate-400" />}
                required
              />
            </>
          ) : (
            <Input
              label="Secret Admin Key"
              type="password"
              placeholder="შეიყვანეთ ადმინის გასაღები"
              value={adminKey}
              onChange={(e) => setAdminKey(e.target.value)}
              icon={<KeyRound className="w-4 h-4 text-slate-400" />}
              required
            />
          )}

          <Button
            type="submit"
            className="w-full mt-2"
            size="lg"
            isLoading={isLoading}
          >
            შესვლა პანელში
          </Button>
        </form>

        <div className="mt-8 pt-6 border-t border-slate-100 text-center">
          <p className="text-[11px] text-slate-400">
            AgroKera Marketplace Platform &copy; 2026. ყველა უფლება დაცულია.
          </p>
        </div>
      </div>
    </div>
  );
};

