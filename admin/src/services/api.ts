import type {
  AdminUser,
  DashboardKpis,
  FarmerItem,
  KycItem,
  OrderItem,
  PayoutItem,
  ProductItem,
} from "../types/index.ts";

const BASE_URL = import.meta.env.VITE_API_URL || "";

class ApiService {
  private token: string | null = null;

  constructor() {
    this.token = localStorage.getItem("agrokera_admin_token");
  }

  setToken(token: string | null) {
    this.token = token;
    if (token) {
      localStorage.setItem("agrokera_admin_token", token);
    } else {
      localStorage.removeItem("agrokera_admin_token");
    }
  }

  getToken(): string | null {
    return this.token;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      ...(options.headers as Record<string, string>),
    };

    if (this.token) {
      headers["Authorization"] = `Bearer ${this.token}`;
    }

    let response: Response;
    try {
      response = await fetch(`${BASE_URL}${endpoint}`, {
        ...options,
        headers,
      });
    } catch (_err) {
      throw new Error(
        "ბექენდ სერვერთან კავშირი ვერ დამყარდა (გთხოვთ გაუშვათ npm run api)"
      );
    }

    if (response.status === 401 || response.status === 403) {
      if (!endpoint.includes("/auth/login")) {
        this.setToken(null);
        window.dispatchEvent(new Event("admin:unauthorized"));
      }
    }

    let data: any = {};
    const text = await response.text();
    if (text) {
      try {
        data = JSON.parse(text);
      } catch (_) {
        data = { error: text };
      }
    }

    if (!response.ok) {
      throw new Error(
        data.error ||
          (response.status === 504 || response.status === 502
            ? "ბექენდ სერვერი მიუწვდომელია (პორტი 3001)"
            : `სერვერის შეცდომა (${response.status})`)
      );
    }

    return data as T;
  }

  // --- Auth ---
  async login(credentials: {
    email?: string;
    password?: string;
    adminKey?: string;
  }): Promise<{ token: string; admin: AdminUser }> {
    const res = await this.request<{ token: string; admin: AdminUser }>(
      "/api/admin/auth/login",
      {
        method: "POST",
        body: JSON.stringify(credentials),
      }
    );
    this.setToken(res.token);
    return res;
  }

  logout() {
    this.setToken(null);
  }

  // --- Dashboard KPIs ---
  async getDashboardStats(): Promise<{
    kpis: DashboardKpis;
    recentOrders: OrderItem[];
    recentKycRequests: KycItem[];
  }> {
    return this.request("/api/admin/stats");
  }

  // --- KYC ---
  async getKycQueue(status = "PENDING_REVIEW"): Promise<{ items: KycItem[] }> {
    return this.request(`/api/admin/kyc?status=${encodeURIComponent(status)}`);
  }

  async reviewKyc(
    farmerId: string,
    review: { status: "VERIFIED" | "REJECTED"; rejectionReason?: string }
  ): Promise<{ success: boolean; message: string }> {
    return this.request(`/api/admin/kyc/${farmerId}/review`, {
      method: "POST",
      body: JSON.stringify(review),
    });
  }

  // --- Farmers ---
  async getFarmers(params: { q?: string; region?: string } = {}): Promise<{
    items: FarmerItem[];
  }> {
    const query = new URLSearchParams();
    if (params.q) query.set("q", params.q);
    if (params.region) query.set("region", params.region);
    return this.request(`/api/admin/farmers?${query.toString()}`);
  }

  // --- Products ---
  async getProducts(params: { q?: string; category?: string } = {}): Promise<{
    items: ProductItem[];
  }> {
    const query = new URLSearchParams();
    if (params.q) query.set("q", params.q);
    if (params.category) query.set("category", params.category);
    return this.request(`/api/admin/products?${query.toString()}`);
  }

  async toggleProductVisibility(
    productId: string
  ): Promise<{ success: boolean; isActive: boolean }> {
    return this.request(`/api/admin/products/${productId}/toggle`, {
      method: "PATCH",
    });
  }

  // --- Orders ---
  async getOrders(status = ""): Promise<{ items: OrderItem[] }> {
    const query = status ? `?status=${encodeURIComponent(status)}` : "";
    return this.request(`/api/admin/orders${query}`);
  }

  // --- Payouts ---
  async getPayouts(): Promise<{ items: PayoutItem[] }> {
    return this.request("/api/admin/payouts");
  }
}

export const apiService = new ApiService();

export function resolveDocumentUrl(
  url?: string | null,
  fallback: string = ""
): string {
  if (!url || typeof url !== "string" || !url.trim()) {
    return fallback;
  }
  const clean = url.trim();
  if (clean.startsWith("s3://agrokera-assets/")) {
    return `/api/assets/${clean.replace("s3://agrokera-assets/", "")}`;
  }
  if (clean.startsWith("s3://")) {
    return `/api/assets/${clean.replace(/^s3:\/\/[^/]+\//, "")}`;
  }
  if (
    clean.startsWith("http://") ||
    clean.startsWith("https://") ||
    clean.startsWith("/") ||
    clean.startsWith("data:")
  ) {
    return clean;
  }
  return `/api/assets/${clean}`;
}

