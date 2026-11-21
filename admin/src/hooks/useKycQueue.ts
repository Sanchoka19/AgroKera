import { useState, useEffect, useCallback } from "react";
import { apiService } from "../services/api.ts";
import type { KycItem, VerificationStatus } from "../types/index.ts";

export function useKycQueue() {
  const [items, setItems] = useState<KycItem[]>([]);
  const [filter, setFilter] = useState<string>("PENDING_REVIEW");
  const [isLoading, setIsLoading] = useState(true);
  const [submittingFarmerId, setSubmittingFarmerId] = useState<string | null>(null);
  const [submittingAction, setSubmittingAction] = useState<"VERIFIED" | "REJECTED" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selectedFarmer, setSelectedFarmer] = useState<KycItem | null>(null);

  const isSubmitting = Boolean(submittingFarmerId);

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
      setSubmittingFarmerId(farmerId);
      setSubmittingAction(status);
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
        setSubmittingFarmerId(null);
        setSubmittingAction(null);
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
    submittingFarmerId,
    submittingAction,
    error,
    selectedFarmer,
    setSelectedFarmer,
    reviewFarmer,
    refresh: fetchQueue,
  };
}

