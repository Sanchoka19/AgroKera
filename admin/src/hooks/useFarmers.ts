import { useState, useEffect, useCallback } from "react";
import { apiService } from "../services/api.ts";
import type { FarmerItem } from "../types/index.ts";

export function useFarmers() {
  const [farmers, setFarmers] = useState<FarmerItem[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [regionFilter, setRegionFilter] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchFarmers = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiService.getFarmers({
        q: searchQuery,
        region: regionFilter,
      });
      setFarmers(data.items);
    } catch (err: any) {
      setError(err.message || "ფერმერების სია ვერ ჩაიტვირთა");
    } finally {
      setIsLoading(false);
    }
  }, [searchQuery, regionFilter]);

  useEffect(() => {
    const timeout = setTimeout(() => {
      fetchFarmers();
    }, 250);
    return () => clearTimeout(timeout);
  }, [fetchFarmers]);

  return {
    farmers,
    searchQuery,
    setSearchQuery,
    regionFilter,
    setRegionFilter,
    isLoading,
    error,
    refresh: fetchFarmers,
  };
}

