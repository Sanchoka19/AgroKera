import React from "react";
import { Package, Eye, EyeOff, RefreshCw } from "lucide-react";
import { useProducts } from "../../hooks/useProducts.ts";
import { Card, CardHeader, CardBody } from "../../components/ui/Card.tsx";
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

const PRODUCT_CATEGORIES = [
  "ბოსტნეული",
  "ხილი და კენკრა",
  "რძის ნაწარმი",
  "თაფლი და მეფუტკრეობა",
  "მარცვლეული",
  "მწვანილი",
  "ხორცი და ფრინველი",
];

export const ProductsView: React.FC = () => {
  const {
    products,
    searchQuery,
    setSearchQuery,
    categoryFilter,
    setCategoryFilter,
    isLoading,
    toggleVisibility,
    refresh,
  } = useProducts();

  return (
    <div className="space-y-6">
      {/* Search and Filters */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div className="flex flex-1 items-center gap-3 max-w-lg">
          <SearchInput
            placeholder="ძიება პროდუქტის ან ფერმის სახელით..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-800 font-medium focus:border-teal-600 focus:outline-none focus:ring-1 focus:ring-teal-600 shrink-0"
          >
            <option value="">ყველა კატეგორია</option>
            {PRODUCT_CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
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

      {/* Products Table Card */}
      <Card>
        <CardHeader
          title="პროდუქციის კატალოგი"
          subtitle={`სულ: ${products.length} პროდუქტი`}
        />
        <CardBody className="p-0">
          {products.length === 0 ? (
            <EmptyState
              title="პროდუქცია ვერ მოიძებნა"
              subtitle="სცადეთ შეცვალოთ ძიების პარამეტრები ან კატეგორია"
              icon={<Package className="w-8 h-8 text-slate-400" />}
            />
          ) : (
            <Table>
              <TableHead>
                <TableRow>
                  <TableHeaderCell>პროდუქტი</TableHeaderCell>
                  <TableHeaderCell>კატეგორია</TableHeaderCell>
                  <TableHeaderCell>ფასი / ერთეული</TableHeaderCell>
                  <TableHeaderCell>მარაგი</TableHeaderCell>
                  <TableHeaderCell>ფერმა / რეგიონი</TableHeaderCell>
                  <TableHeaderCell>სტატუსი</TableHeaderCell>
                  <TableHeaderCell className="text-right">მოქმედება</TableHeaderCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {products.map((product) => (
                  <TableRow key={product.id}>
                    <TableCell>
                      <div className="font-bold text-slate-900">
                        {product.title}
                      </div>
                      {product.description ? (
                        <div className="text-xs text-slate-500 truncate max-w-xs">
                          {product.description}
                        </div>
                      ) : null}
                    </TableCell>
                    <TableCell>
                      <span className="text-xs font-semibold text-slate-700 bg-slate-100 px-2 py-0.5 rounded">
                        {product.category}
                      </span>
                    </TableCell>
                    <TableCell className="font-bold text-slate-900">
                      {product.price?.toFixed(2)} ₾{" "}
                      <span className="text-xs text-slate-500 font-normal">
                        / {product.unit || "კგ"}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span
                        className={`text-xs font-bold px-2 py-0.5 rounded ${
                          product.stockQuantity <= 5
                            ? "bg-rose-50 text-rose-700"
                            : "bg-emerald-50 text-emerald-700"
                        }`}
                      >
                        {product.stockQuantity} {product.unit || "კგ"}
                      </span>
                    </TableCell>
                    <TableCell>
                      <div className="font-semibold text-slate-800 text-xs">
                        {product.farmer?.farmName}
                      </div>
                      <div className="text-[11px] text-slate-500">
                        {product.farmer?.region}
                      </div>
                    </TableCell>
                    <TableCell>
                      {product.isActive ? (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-600" />
                          აქტიური
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-slate-600 bg-slate-100 px-2 py-0.5 rounded-full border border-slate-200">
                          <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
                          დამალული
                        </span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant={product.isActive ? "outline" : "secondary"}
                        size="sm"
                        onClick={() => toggleVisibility(product.id)}
                      >
                        {product.isActive ? (
                          <>
                            <EyeOff className="w-3.5 h-3.5 text-slate-500" />
                            დამალვა
                          </>
                        ) : (
                          <>
                            <Eye className="w-3.5 h-3.5 text-teal-600" />
                            გამოჩენა
                          </>
                        )}
                      </Button>
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

