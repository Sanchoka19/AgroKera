import React from "react";
import { Users, MapPin, Phone, Mail, Star, Package, RefreshCw } from "lucide-react";
import { useFarmers } from "../../hooks/useFarmers.ts";
import { Card, CardHeader, CardBody } from "../../components/ui/Card.tsx";
import { Badge } from "../../components/ui/Badge.tsx";
import { Button } from "../../components/ui/Button.tsx";
import { SearchInput } from "../../components/ui/Input.tsx";
import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
  EmptyState,
} from "../../components/ui/Table.tsx";

const GEORGIAN_REGIONS = [
  "კახეთი",
  "იმერეთი",
  "შიდა ქართლი",
  "ქვემო ქართლი",
  "სამეგრელო",
  "გურია",
  "აჭარა",
  "მცხეთა-მთიანეთი",
  "სამცხე-ჯავახეთი",
  "რაჭა-ლეჩხუმი",
];

export const FarmersView: React.FC = () => {
  const {
    farmers,
    searchQuery,
    setSearchQuery,
    regionFilter,
    setRegionFilter,
    isLoading,
    refresh,
  } = useFarmers();

  return (
    <div className="space-y-6">
      {/* Search and Filters Bar */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div className="flex flex-1 items-center gap-3 max-w-lg">
          <SearchInput
            placeholder="ძიება სახელით, ფერმით ან ტელეფონით..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          <select
            value={regionFilter}
            onChange={(e) => setRegionFilter(e.target.value)}
            className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 font-medium focus:border-teal-600 focus:outline-none focus:ring-1 focus:ring-teal-600 shrink-0"
          >
            <option value="">ყველა რეგიონი</option>
            {GEORGIAN_REGIONS.map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </select>
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

      {/* Main Farmers Table */}
      <Card>
        <CardHeader
          title="რეგისტრირებული ფერმერები"
          subtitle={`სულ: ${farmers.length} მეურნეობა`}
        />
        <CardBody className="p-0">
          {farmers.length === 0 ? (
            <EmptyState
              title="ფერმერები ვერ მოიძებნა"
              subtitle="სცადეთ შეცვალოთ ძიების პარამეტრები ან რეგიონი"
              icon={<Users className="w-8 h-8 text-slate-400" />}
            />
          ) : (
            <Table>
              <TableHead>
                <TableRow>
                  <TableHeaderCell>მეურნეობის სახელი</TableHeaderCell>
                  <TableHeaderCell>მესაკუთრე</TableHeaderCell>
                  <TableHeaderCell>რეგიონი</TableHeaderCell>
                  <TableHeaderCell>კონტაქტი</TableHeaderCell>
                  <TableHeaderCell>პროდუქცია</TableHeaderCell>
                  <TableHeaderCell>რეიტინგი</TableHeaderCell>
                  <TableHeaderCell>სტატუსი</TableHeaderCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {farmers.map((farmer) => (
                  <TableRow key={farmer.id}>
                    <TableCell className="font-bold text-slate-900">
                      {farmer.farmName}
                    </TableCell>
                    <TableCell className="font-semibold text-slate-800">
                      {farmer.user?.fullName}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1.5 text-xs text-slate-600 font-medium">
                        <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        {farmer.region}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-xs text-slate-700 flex items-center gap-1.5">
                        <Phone className="w-3 h-3 text-slate-400" />
                        {farmer.user?.phoneNumber || "—"}
                      </div>
                      {farmer.user?.email ? (
                        <div className="text-[11px] text-slate-500 flex items-center gap-1.5 mt-0.5">
                          <Mail className="w-3 h-3 text-slate-400" />
                          {farmer.user.email}
                        </div>
                      ) : null}
                    </TableCell>
                    <TableCell>
                      <div className="inline-flex items-center gap-1 text-xs font-bold text-slate-700 bg-slate-100 px-2 py-0.5 rounded">
                        <Package className="w-3 h-3 text-slate-500" />
                        {farmer._count?.products ?? 0}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded w-fit">
                        <Star className="w-3 h-3 fill-amber-400 text-amber-500" />
                        {farmer.rating?.toFixed(1) ?? "5.0"}
                        <span className="text-slate-400 font-normal">
                          ({farmer.reviewCount ?? 0})
                        </span>
                      </div>
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
  );
};

