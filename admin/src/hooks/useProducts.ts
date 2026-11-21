import { useState, useEffect, useCallback } from "react";
import { apiService } from "../services/api.ts";
import type { ProductItem } from "../types/index.ts";

export function useProducts() {
  const [products, setProducts] = useState<ProductItem[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProducts = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await apiService.getProducts({
        q: searchQuery,
        category: categoryFilter,
      });
      setProducts(data.items);
    } catch (err: any) {
      setError(err.message || "პროდუქცია ვერ ჩაიტვირთა");
    } finally {
      setIsLoading(false);
    }
  }, [searchQuery, categoryFilter]);

  useEffect(() => {
    const timeout = setTimeout(() => {
      fetchProducts();
    }, 250);
    return () => clearTimeout(timeout);
  }, [fetchProducts]);

  const toggleVisibility = useCallback(async (productId: string) => {
    try {
      const res = await apiService.toggleProductVisibility(productId);
      setProducts((prev) =>
        prev.map((p) => (p.id === productId ? { ...p, isActive: res.isActive } : p))
      );
    } catch (err: any) {
      setError(err.message || "სტატუსის შეცვლა ვერ მოხერხდა");
    }
  }, []);

  return {
    products,
    searchQuery,
    setSearchQuery,
    categoryFilter,
    setCategoryFilter,
    isLoading,
    error,
    toggleVisibility,
    refresh: fetchProducts,
  };
}

