import React from "react";
import {
  ShieldAlert,
  Users,
  Package,
  CircleDollarSign,
  ArrowRight,
  RefreshCw,
  ShoppingBag,
} from "lucide-react";
import { useDashboardStats } from "../../hooks/useDashboardStats.ts";
import { StatCard } from "../../components/ui/StatCard.tsx";
import { Card, CardHeader, CardBody } from "../../components/ui/Card.tsx";
import { Badge } from "../../components/ui/Badge.tsx";
import { Button } from "../../components/ui/Button.tsx";
import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
  EmptyState,
} from "../../components/ui/Table.tsx";
import type { NavTab } from "../../components/layout/Sidebar.tsx";

interface DashboardViewProps {
  onNavigate: (tab: NavTab) => void;
}

export const DashboardView: React.FC<DashboardViewProps> = ({ onNavigate }) => {
  const { kpis, recentOrders, recentKycRequests, isLoading, refresh } =
    useDashboardStats();

  return (
    <div className="space-y-8">
      {/* Top Banner & Refresh */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-black text-slate-900 tracking-tight">
            პლატფორმის ოპერაციული მიმოხილვა
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            რეალურ დროში განახლებული სტატისტიკა და აქტივობები
          </p>
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={refresh}
          isLoading={isLoading}
        >
          <RefreshCw className="w-3.5 h-3.5" />
          განახლება
        </Button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard
          title="ვერიფიკაციის რიგი"
          value={kpis?.pendingKycCount ?? 0}
          subtitle="განიხილეთ პირადობის მოწმობები"
          icon={<ShieldAlert className="w-6 h-6" />}
          variant="amber"
          trend={
            kpis && kpis.pendingKycCount > 0
              ? `${kpis.pendingKycCount} მოლოდინში`
              : undefined
          }
        />
        <StatCard
          title="რეგისტრირებული ფერმები"
          value={kpis?.totalFarmersCount ?? 0}
          subtitle="საქართველოს რეგიონებიდან"
          icon={<Users className="w-6 h-6" />}
          variant="teal"
        />
        <StatCard
          title="აქტიური პროდუქცია"
          value={kpis?.totalProductsCount ?? 0}
          subtitle="მარკეტფლეისზე განთავსებული"
          icon={<Package className="w-6 h-6" />}
          variant="default"
        />
        <StatCard
          title="ჯამური ბრუნვა (GMV)"
          value={`${kpis?.totalGmv?.toFixed(2) ?? "0.00"} ₾`}
          subtitle="შესრულებული შეკვეთები"
          icon={<CircleDollarSign className="w-6 h-6" />}
          variant="default"
        />
      </div>

      {/* KYC Alert Action Banner if Pending */}
      {kpis && kpis.pendingKycCount > 0 ? (
        <div className="bg-amber-500/10 border border-amber-500/20 rounded-2xl p-5 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-amber-500 text-slate-950 rounded-xl">
              <ShieldAlert className="w-6 h-6" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-slate-900">
                {kpis.pendingKycCount} ფერმერი ელოდება პირადობის ვერიფიკაციას
              </h4>
              <p className="text-xs text-slate-600 mt-0.5">
                გადაამოწმეთ ატვირთული დოკუმენტები, რათა ფერმერებმა შეძლონ პროდუქციის გამოქვეყნება.
              </p>
            </div>
          </div>
          <Button
            variant="primary"
            size="md"
            onClick={() => onNavigate("kyc")}
            className="bg-amber-600 hover:bg-amber-700 text-white shrink-0"
          >
            რიგის განხილვა
            <ArrowRight className="w-4 h-4" />
          </Button>
        </div>
      ) : null}

      {/* Grid: Recent Orders & Recent KYC Requests */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Recent Orders */}
        <Card>
          <CardHeader
            title="ბოლო შეკვეთები"
            subtitle="უახლესი ტრანზაქციები"
            action={
              <Button
                variant="ghost"
                size="sm"
                onClick={() => onNavigate("orders")}
              >
                სრულად ნახვა
                <ArrowRight className="w-3.5 h-3.5" />
              </Button>
            }
          />
          <CardBody className="p-0">
            {recentOrders.length === 0 ? (
              <EmptyState
                title="შეკვეთები ჯერ არ არის"
                icon={<ShoppingBag className="w-8 h-8" />}
              />
            ) : (
              <Table>
                <TableHead>
                  <TableRow>
                    <TableHeaderCell>შეკვეთა</TableHeaderCell>
                    <TableHeaderCell>მყიდველი</TableHeaderCell>
                    <TableHeaderCell>თანხა</TableHeaderCell>
                    <TableHeaderCell>სტატუსი</TableHeaderCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {recentOrders.map((order) => (
                    <TableRow key={order.id}>
                      <TableCell className="font-mono text-xs font-bold text-slate-500">
                        #{order.id.slice(-6)}
                      </TableCell>
                      <TableCell className="font-semibold text-slate-900">
                        {order.client?.fullName || order.user?.fullName || "კლიენტი"}
                      </TableCell>
                      <TableCell className="font-bold text-slate-900">
                        {order.totalAmount?.toFixed(2)} ₾
                      </TableCell>
                      <TableCell>
                        <Badge status={order.status} size="sm" />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardBody>
        </Card>

        {/* Recent KYC Requests */}
        <Card>
          <CardHeader
            title="ვერიფიკაციის მოთხოვნები"
            subtitle="ახლად ატვირთული საბუთები"
            action={
              <Button
                variant="ghost"
                size="sm"
                onClick={() => onNavigate("kyc")}
              >
                სრულად ნახვა
                <ArrowRight className="w-3.5 h-3.5" />
              </Button>
            }
          />
          <CardBody className="p-0">
            {recentKycRequests.length === 0 ? (
              <EmptyState
                title="მომლოდინე მოთხოვნები არ არის"
                subtitle="ყველა ფერმერი გადამოწმებულია"
                icon={<ShieldAlert className="w-8 h-8 text-teal-600" />}
              />
            ) : (
              <Table>
                <TableHead>
                  <TableRow>
                    <TableHeaderCell>ფერმერი / მეურნეობა</TableHeaderCell>
                    <TableHeaderCell>რეგიონი</TableHeaderCell>
                    <TableHeaderCell>სტატუსი</TableHeaderCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {recentKycRequests.map((farmer) => (
                    <TableRow key={farmer.id}>
                      <TableCell>
                        <div className="font-bold text-slate-900">
                          {farmer.user?.fullName}
                        </div>
                        <div className="text-xs text-slate-500">
                          {farmer.farmName}
                        </div>
                      </TableCell>
                      <TableCell className="text-xs text-slate-600">
                        {farmer.region}
                      </TableCell>
                      <TableCell>
                        <Badge
                          status={farmer.user?.verificationStatus}
                          size="sm"
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardBody>
        </Card>
      </div>
    </div>
  );
};

