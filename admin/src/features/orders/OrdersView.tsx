import React from "react";
import { ShoppingCart, RefreshCw } from "lucide-react";
import { useOrders } from "../../hooks/useOrders.ts";
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

const ORDER_STATUS_TABS = [
  { id: "", label: "ყველა" },
  { id: "PENDING", label: "მოლოდინში" },
  { id: "IN_PROGRESS", label: "პროცესშია" },
  { id: "CONFIRMED", label: "დადასტურებული" },
  { id: "COMPLETED", label: "დასრულებული" },
  { id: "CANCELLED", label: "გაუქმებული" },
];

export const OrdersView: React.FC = () => {
  const { orders, statusFilter, setStatusFilter, isLoading, refresh } =
    useOrders();

  return (
    <div className="space-y-6">
      {/* Status Filter Tabs */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div className="flex rounded-xl bg-slate-200/70 p-1 text-xs font-bold text-slate-600 overflow-x-auto">
          {ORDER_STATUS_TABS.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setStatusFilter(tab.id)}
              className={`px-3.5 py-1.5 rounded-lg whitespace-nowrap transition-all ${
                statusFilter === tab.id
                  ? "bg-white text-slate-900 shadow-xs"
                  : "hover:text-slate-900"
              }`}
            >
              {tab.label}
            </button>
          ))}
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

      {/* Orders Table Card */}
      <Card>
        <CardHeader
          title="შეკვეთების რეესტრი"
          subtitle={`სულ: ${orders.length} შეკვეთა`}
        />
        <CardBody className="p-0">
          {orders.length === 0 ? (
            <EmptyState
              title="შეკვეთები არ მოიძებნა"
              subtitle="ამ სტატუსით შეკვეთები არ ფიქსირდება"
              icon={<ShoppingCart className="w-8 h-8 text-slate-400" />}
            />
          ) : (
            <Table>
              <TableHead>
                <TableRow>
                  <TableHeaderCell>შეკვეთის ID</TableHeaderCell>
                  <TableHeaderCell>მყიდველი</TableHeaderCell>
                  <TableHeaderCell>პროდუქტები</TableHeaderCell>
                  <TableHeaderCell>თანხა</TableHeaderCell>
                  <TableHeaderCell>თარიღი</TableHeaderCell>
                  <TableHeaderCell>სტატუსი</TableHeaderCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {orders.map((order) => (
                  <TableRow key={order.id}>
                    <TableCell className="font-mono text-xs font-bold text-teal-800">
                      #{order.id.slice(-8)}
                    </TableCell>
                    <TableCell>
                      <div className="font-bold text-slate-900 text-xs">
                        {order.client?.fullName || order.user?.fullName || "კლიენტი"}
                      </div>
                      <div className="text-[11px] text-slate-500">
                        {order.client?.phoneNumber || order.user?.phoneNumber || "—"}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-xs text-slate-800 max-w-xs truncate">
                        {order.items
                          ?.map(
                            (it) => `${it.product?.title} (x${it.quantity})`
                          )
                          .join(", ") || "—"}
                      </div>
                    </TableCell>
                    <TableCell className="font-black text-slate-900 text-sm">
                      {order.totalAmount?.toFixed(2)} ₾
                    </TableCell>
                    <TableCell className="text-xs text-slate-500 font-medium">
                      {new Date(order.createdAt).toLocaleDateString("ka-GE", {
                        month: "short",
                        day: "numeric",
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
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
    </div>
  );
};

