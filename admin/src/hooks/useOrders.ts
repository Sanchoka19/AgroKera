import { useState, useEffect, useCallback } from "react";
import { apiService } from "../services/api.ts";
import type { OrderItem } from "../types/index.ts";

export function useOrders() {
  const [orders, setOrders] = useState<OrderItem[]>([]);
  const [statusFilter, setStatusFilter] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchOrders = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiService.getOrders(statusFilter);
      setOrders(data.items);
    } catch (err: any) {
      setError(err.message || "შეკვეთები ვერ ჩაიტვირთა");
    } finally {
      setIsLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  return {
    orders,
    statusFilter,
    setStatusFilter,
    isLoading,
    error,
    refresh: fetchOrders,
  };
}

