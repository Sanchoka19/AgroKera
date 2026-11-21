import { useState, useEffect, useCallback } from "react";
import { apiService } from "../services/api.ts";
import type { DashboardKpis, KycItem, OrderItem } from "../types/index.ts";

export function useDashboardStats() {
  const [kpis, setKpis] = useState<DashboardKpis | null>(null);
  const [recentOrders, setRecentOrders] = useState<OrderItem[]>([]);
  const [recentKycRequests, setRecentKycRequests] = useState<KycItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStats = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiService.getDashboardStats();
      setKpis(data.kpis);
      setRecentOrders(data.recentOrders);
      setRecentKycRequests(data.recentKycRequests);
    } catch (err: any) {
      setError(err.message || "სტატისტიკა ვერ ჩაიტვირთა");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchStats();
  }, [fetchStats]);

  return {
    kpis,
    recentOrders,
    recentKycRequests,
    isLoading,
    error,
    refresh: fetchStats,
  };
}

