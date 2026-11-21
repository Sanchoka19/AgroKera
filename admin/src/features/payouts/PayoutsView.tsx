import React from "react";
import { Download, RefreshCw, Landmark } from "lucide-react";
import { usePayouts } from "../../hooks/usePayouts.ts";
import { Card, CardBody } from "../../components/ui/Card.tsx";
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

export const PayoutsView: React.FC = () => {
  const { payouts, isLoading, exportToCsv, refresh } = usePayouts();

  const totalGross = payouts.reduce((acc, p) => acc + p.totalGrossAmount, 0);
  const totalCommission = payouts.reduce((acc, p) => acc + p.commissionFee, 0);
  const totalNet = payouts.reduce((acc, p) => acc + p.netPayoutAmount, 0);

  return (
    <div className="space-y-6">
      {/* Financial Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
            ჯამური გაყიდვები (Gross)
          </p>
          <p className="text-2xl font-black text-slate-900 mt-1">
            {totalGross.toFixed(2)} ₾
          </p>
          <p className="text-xs text-slate-400 mt-1">
            შესრულებული შეკვეთების მოცულობა
          </p>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <p className="text-xs font-semibold text-teal-700 uppercase tracking-wider">
            პლატფორმის საკომისიო (5%)
          </p>
          <p className="text-2xl font-black text-teal-700 mt-1">
            {totalCommission.toFixed(2)} ₾
          </p>
          <p className="text-xs text-slate-400 mt-1">AgroKera-ს შემოსავალი</p>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <p className="text-xs font-semibold text-emerald-700 uppercase tracking-wider">
            ფერმერებზე გასაცემი (Net)
          </p>
          <p className="text-2xl font-black text-emerald-700 mt-1">
            {totalNet.toFixed(2)} ₾
          </p>
          <p className="text-xs text-slate-400 mt-1">
            საბანკო გადარიცხვის ჯამური მოცულობა
          </p>
        </div>
      </div>

      {/* Action Header */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div>
          <h3 className="text-base font-bold text-slate-900">
            ფერმერების ანგარიშსწორების რეესტრი
          </h3>
          <p className="text-xs text-slate-500">
            ექსპორტი გაუკეთეთ რეესტრს და ატვირთეთ ინტერნეტ ბანკში
          </p>
        </div>

        <div className="flex flex-wrap sm:flex-nowrap items-center gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={refresh}
            isLoading={isLoading}
          >
            <RefreshCw className="w-3.5 h-3.5" />
            განახლება
          </Button>
          <Button
            variant="primary"
            size="sm"
            onClick={exportToCsv}
            disabled={payouts.length === 0}
            className="bg-emerald-700 hover:bg-emerald-800"
          >
            <Download className="w-4 h-4" />
            CSV ექსპორტი ბანკისთვის (BOG / TBC)
          </Button>
        </div>
      </div>

      {/* Payouts Table */}
      <Card>
        <CardBody className="p-0">
          {payouts.length === 0 ? (
            <EmptyState
              title="გასაცემი თანხები არ ფიქსირდება"
              subtitle="შესრულებული შეკვეთების შემდეგ აქ გამოჩნდება ფერმერთა რეესტრი"
              icon={<Landmark className="w-8 h-8 text-slate-400" />}
            />
          ) : (
            <Table>
              <TableHead>
                <TableRow>
                  <TableHeaderCell>მეურნეობა</TableHeaderCell>
                  <TableHeaderCell>მიმღები (მფლობელი)</TableHeaderCell>
                  <TableHeaderCell>რეგიონი / ტელეფონი</TableHeaderCell>
                  <TableHeaderCell>შეკვეთები</TableHeaderCell>
                  <TableHeaderCell>სრული თანხა</TableHeaderCell>
                  <TableHeaderCell>საკომისიო (5%)</TableHeaderCell>
                  <TableHeaderCell className="text-right">
                    ჩასარიცხი (Net)
                  </TableHeaderCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {payouts.map((p) => (
                  <TableRow key={p.farmerId}>
                    <TableCell className="font-bold text-slate-900">
                      {p.farmName}
                    </TableCell>
                    <TableCell className="font-semibold text-slate-800">
                      {p.farmerName}
                    </TableCell>
                    <TableCell>
                      <div className="text-xs text-slate-700">{p.region}</div>
                      <div className="text-[11px] text-slate-500 font-mono">
                        {p.phoneNumber}
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="text-xs font-bold text-slate-700 bg-slate-100 px-2 py-0.5 rounded">
                        {p.totalCompletedOrders} შეკვეთა
                      </span>
                    </TableCell>
                    <TableCell className="font-semibold text-slate-800 text-xs">
                      {p.totalGrossAmount.toFixed(2)} ₾
                    </TableCell>
                    <TableCell className="text-xs text-slate-500 font-medium">
                      -{p.commissionFee.toFixed(2)} ₾
                    </TableCell>
                    <TableCell className="text-right font-black text-emerald-800 text-sm">
                      {p.netPayoutAmount.toFixed(2)} ₾
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
