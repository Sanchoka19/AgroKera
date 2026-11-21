import { useState, useEffect, useCallback } from "react";
import { apiService } from "../services/api.ts";
import type { PayoutItem } from "../types/index.ts";

export function usePayouts() {
  const [payouts, setPayouts] = useState<PayoutItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPayouts = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiService.getPayouts();
      setPayouts(data.items);
    } catch (err: any) {
      setError(err.message || "ანგარიშსწორების რეესტრი ვერ ჩაიტვირთა");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPayouts();
  }, [fetchPayouts]);

  const exportToCsv = useCallback(() => {
    if (payouts.length === 0) return;

    const headers = [
      "Farmer ID",
      "Farm Name",
      "Beneficiary Name",
      "Phone Number",
      "Region",
      "Completed Orders",
      "Gross Amount (GEL)",
      "Commission Fee (GEL)",
      "Net Payout (GEL)",
    ];

    const rows = payouts.map((p) => [
      p.farmerId,
      `"${p.farmName.replace(/"/g, '""')}"`,
      `"${p.farmerName.replace(/"/g, '""')}"`,
      p.phoneNumber,
      p.region,
      p.totalCompletedOrders,
      p.totalGrossAmount.toFixed(2),
      p.commissionFee.toFixed(2),
      p.netPayoutAmount.toFixed(2),
    ]);

    const csvContent =
      "data:text/csv;charset=utf-8,\uFEFF" +
      [headers.join(","), ...rows.map((e) => e.join(","))].join("\n");

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute(
      "download",
      `agrokera_payouts_${new Date().toISOString().slice(0, 10)}.csv`
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }, [payouts]);

  return {
    payouts,
    isLoading,
    error,
    exportToCsv,
    refresh: fetchPayouts,
  };
}

