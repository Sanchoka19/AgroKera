import { useState, useEffect, useCallback } from "react";
import { apiService } from "../services/api.ts";
import type { AdminUser } from "../types/index.ts";

export function useAdminAuth() {
  const [admin, setAdmin] = useState<AdminUser | null>(() => {
    const saved = localStorage.getItem("agrokera_admin_user");
    return saved ? JSON.parse(saved) : null;
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isAuthenticated = Boolean(admin && apiService.getToken());

  useEffect(() => {
    const handleUnauthorized = () => {
      setAdmin(null);
      localStorage.removeItem("agrokera_admin_user");
    };
    window.addEventListener("admin:unauthorized", handleUnauthorized);
    return () =>
      window.removeEventListener("admin:unauthorized", handleUnauthorized);
  }, []);

  const login = useCallback(
    async (credentials: {
      email?: string;
      password?: string;
      adminKey?: string;
    }) => {
      setIsLoading(true);
      setError(null);
      try {
        const res = await apiService.login(credentials);
        setAdmin(res.admin);
        localStorage.setItem("agrokera_admin_user", JSON.stringify(res.admin));
        return true;
      } catch (err: any) {
        setError(err.message || "ავტორიზაცია ვერ მოხერხდა");
        return false;
      } finally {
        setIsLoading(false);
      }
    },
    []
  );

  const logout = useCallback(() => {
    apiService.logout();
    setAdmin(null);
    localStorage.removeItem("agrokera_admin_user");
  }, []);

  return {
    admin,
    isAuthenticated,
    isLoading,
    error,
    login,
    logout,
  };
}

