import { useState, useEffect, useCallback } from "react";
import { apiService } from "../services/api.ts";
import type { KycItem, VerificationStatus } from "../types/index.ts";

export function useKycQueue() {
  const [items, setItems] = useState<KycItem[]>([]);
  const [filter, setFilter] = useState<string>("PENDING_REVIEW");
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedFarmer, setSelectedFarmer] = useState<KycItem | null>(null);

  const fetchQueue = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiService.getKycQueue(filter);
      setItems(data.items);
    } catch (err: any) {
      setError(err.message || "ვერიფიკაციის რიგი ვერ ჩაიტვირთა");
    } finally {
      setIsLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    fetchQueue();
  }, [fetchQueue]);

  const reviewFarmer = useCallback(
    async (
      farmerId: string,
      status: "VERIFIED" | "REJECTED",
      rejectionReason?: string
    ) => {
      setIsSubmitting(true);
      setError(null);
      try {
        await apiService.reviewKyc(farmerId, { status, rejectionReason });
        // Optimistically update list
        setItems((prev) =>
          prev.map((item) =>
            item.id === farmerId
              ? {
                  ...item,
                  user: {
                    ...item.user,
                    verificationStatus: status as VerificationStatus,
                  },
                }
              : item
          )
        );
        if (selectedFarmer?.id === farmerId) {
          setSelectedFarmer(null);
        }
        return true;
      } catch (err: any) {
        setError(err.message || "ვერიფიკაციის სტატუსის განახლება ვერ მოხერხდა");
        return false;
      } finally {
        setIsSubmitting(false);
      }
    },
    [selectedFarmer]
  );

  return {
    items,
    filter,
    setFilter,
    isLoading,
    isSubmitting,
    error,
    selectedFarmer,
    setSelectedFarmer,
    reviewFarmer,
    refresh: fetchQueue,
  };
}

