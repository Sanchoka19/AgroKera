import React, { useState } from "react";
import {
  CheckCircle2,
  XCircle,
  Eye,
  RefreshCw,
  FileText,
  MapPin,
  Phone,
  Mail,
} from "lucide-react";
import { useKycQueue } from "../../hooks/useKycQueue.ts";
import { resolveDocumentUrl } from "../../services/api.ts";
import { Card, CardHeader, CardBody } from "../../components/ui/Card.tsx";
import { Badge } from "../../components/ui/Badge.tsx";
import { Button } from "../../components/ui/Button.tsx";
import { Modal } from "../../components/ui/Modal.tsx";
import { ConfirmationModal } from "../../components/ui/ConfirmationModal.tsx";
import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
  EmptyState,
} from "../../components/ui/Table.tsx";
import type { KycItem } from "../../types/index.ts";

export const KycQueueView: React.FC = () => {
  const {
    items,
    filter,
    setFilter,
    isLoading,
    isSubmitting,
    submittingFarmerId,
    submittingAction,
    selectedFarmer,
    setSelectedFarmer,
    reviewFarmer,
    refresh,
  } = useKycQueue();

  const [farmerToApprove, setFarmerToApprove] = useState<KycItem | null>(null);
  const [farmerToReject, setFarmerToReject] = useState<KycItem | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [activeImagePreview, setActiveImagePreview] = useState<string | null>(
    null
  );

  const filterTabs = [
    { id: "PENDING_REVIEW", label: "მოლოდინში" },
    { id: "VERIFIED", label: "ვერიფიცირებული" },
    { id: "REJECTED", label: "დახარვეზებული" },
    { id: "ALL", label: "ყველა" },
  ];

  return (
    <div className="space-y-6">
      {/* Top Bar with Filter Tabs */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div className="flex rounded-xl bg-slate-200/70 p-1 text-xs font-bold text-slate-600">
          {filterTabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilter(tab.id)}
              className={`px-4 py-2 rounded-lg transition-all ${
                filter === tab.id
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

      {/* Main Table Card */}
      <Card>
        <CardHeader
          title="ვერიფიკაციის რეესტრი"
          subtitle={`სულ ჩანაწერები: ${items.length}`}
        />
        <CardBody className="p-0">
          {items.length === 0 ? (
            <EmptyState
              title="ჩანაწერები არ მოიძებნა"
              subtitle="ამ ფილტრის მიხედვით მოთხოვნები არ არის"
              icon={<FileText className="w-8 h-8 text-slate-400" />}
            />
          ) : (
            <Table>
              <TableHead>
                <TableRow>
                  <TableHeaderCell>ფერმერი / მფლობელი</TableHeaderCell>
                  <TableHeaderCell>მეურნეობის სახელი</TableHeaderCell>
                  <TableHeaderCell>რეგიონი / მისამართი</TableHeaderCell>
                  <TableHeaderCell>კონტაქტი</TableHeaderCell>
                  <TableHeaderCell>სტატუსი</TableHeaderCell>
                  <TableHeaderCell className="text-right">მოქმედება</TableHeaderCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {items.map((farmer) => (
                  <TableRow key={farmer.id}>
                    <TableCell>
                      <div className="font-bold text-slate-900">
                        {farmer.user?.fullName}
                      </div>
                      <div className="text-xs text-slate-400 font-mono">
                        ID: {farmer.userId.slice(-6)}
                      </div>
                    </TableCell>
                    <TableCell className="font-semibold text-slate-800">
                      {farmer.farmName}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1.5 text-xs text-slate-700 font-medium">
                        <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        <span>{farmer.region}</span>
                      </div>
                      {farmer.address ? (
                        <div className="text-[11px] text-slate-500 mt-0.5 truncate max-w-xs">
                          {farmer.address}
                        </div>
                      ) : null}
                    </TableCell>
                    <TableCell>
                      <div className="text-xs text-slate-700 font-medium flex items-center gap-1.5">
                        <Phone className="w-3 h-3 text-slate-400" />
                        {farmer.user?.phoneNumber || "არ არის მითითებული"}
                      </div>
                      {farmer.user?.email ? (
                        <div className="text-[11px] text-slate-500 flex items-center gap-1.5 mt-0.5">
                          <Mail className="w-3 h-3 text-slate-400" />
                          {farmer.user.email}
                        </div>
                      ) : null}
                    </TableCell>
                    <TableCell>
                      <Badge
                        status={farmer.user?.verificationStatus}
                        size="md"
                      />
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setSelectedFarmer(farmer)}
                        >
                          <Eye className="w-3.5 h-3.5" />
                          საბუთების ნახვა
                        </Button>
                        {farmer.user?.verificationStatus ===
                        "PENDING_REVIEW" ? (
                          <>
                            <Button
                              variant="primary"
                              size="sm"
                              onClick={() => setFarmerToApprove(farmer)}
                              isLoading={
                                submittingFarmerId === farmer.id &&
                                submittingAction === "VERIFIED"
                              }
                              disabled={isSubmitting}
                            >
                              <CheckCircle2 className="w-3.5 h-3.5" />
                              დადასტურება
                            </Button>
                            <Button
                              variant="danger"
                              size="sm"
                              onClick={() => {
                                setFarmerToReject(farmer);
                                setRejectReason("");
                              }}
                              isLoading={
                                submittingFarmerId === farmer.id &&
                                submittingAction === "REJECTED"
                              }
                              disabled={isSubmitting}
                            >
                              <XCircle className="w-3.5 h-3.5" />
                              დახარვეზება
                            </Button>
                          </>
                        ) : null}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardBody>
      </Card>

      {/* Document Inspector Modal */}
      {selectedFarmer && !farmerToReject ? (
        <Modal
          isOpen={Boolean(selectedFarmer)}
          onClose={() => setSelectedFarmer(null)}
          title={`ვერიფიკაციის დეტალები — ${selectedFarmer.user.fullName}`}
          description={`მეურნეობა: ${selectedFarmer.farmName} (${selectedFarmer.region})`}
          maxWidth="2xl"
        >
          <div className="space-y-6">
            {/* Farmer Profile Summary */}
            <div className="grid grid-cols-2 gap-4 bg-slate-50 p-4 rounded-xl border border-slate-200/80 text-xs">
              <div>
                <span className="text-slate-400 block">ფერმერი:</span>
                <span className="font-bold text-slate-800">
                  {selectedFarmer.user.fullName}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block">ტელეფონი:</span>
                <span className="font-bold text-slate-800">
                  {selectedFarmer.user.phoneNumber || "—"}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block">მისამართი:</span>
                <span className="font-bold text-slate-800">
                  {selectedFarmer.region}, {selectedFarmer.address || "—"}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block">სტატუსი:</span>
                <Badge
                  status={selectedFarmer.user.verificationStatus}
                  size="sm"
                />
              </div>
            </div>

            {/* ID Cards Preview */}
            <div>
              <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-3">
                ატვირთული პირადობის მოწმობა
              </h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Front Side */}
                {(() => {
                  const frontSrc = resolveDocumentUrl(selectedFarmer.idCardFrontUrl);
                  return (
                    <div className="border border-slate-200 rounded-xl p-3 bg-slate-50">
                      <div className="flex items-center justify-between mb-2">
                        <p className="text-xs font-semibold text-slate-700">
                          წინა მხარე (Front)
                        </p>
                        <span className="text-[10px] text-teal-700 bg-teal-50 px-1.5 py-0.5 rounded font-bold">
                          ID Card
                        </span>
                      </div>
                      {frontSrc ? (
                        <div
                          onClick={() => setActiveImagePreview(frontSrc)}
                          className="relative aspect-4/3 rounded-lg overflow-hidden bg-slate-100 cursor-pointer group flex items-center justify-center border border-slate-200 shadow-xs"
                        >
                          <img
                            src={frontSrc}
                            alt="ID Front"
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                          />
                          <div className="absolute inset-0 bg-slate-950/40 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity text-white font-bold text-xs gap-1.5 backdrop-blur-2xs">
                            <Eye className="w-4 h-4" />
                            გადიდება
                          </div>
                        </div>
                      ) : (
                        <div className="aspect-4/3 rounded-lg border-2 border-dashed border-slate-200 flex flex-col items-center justify-center text-slate-400 bg-white p-4 text-center">
                          <FileText className="w-8 h-8 mb-2 text-slate-300" />
                          <span className="text-xs font-medium text-slate-600">
                            დოკუმენტი არ არის ატვირთული
                          </span>
                          <span className="text-[11px] text-slate-400 mt-0.5">
                            ფერმერს წინა მხარე არ დაუმატებია
                          </span>
                        </div>
                      )}
                    </div>
                  );
                })()}

                {/* Back Side */}
                {(() => {
                  const backSrc = resolveDocumentUrl(selectedFarmer.idCardBackUrl);
                  return (
                    <div className="border border-slate-200 rounded-xl p-3 bg-slate-50">
                      <div className="flex items-center justify-between mb-2">
                        <p className="text-xs font-semibold text-slate-700">
                          უკანა მხარე (Back)
                        </p>
                        <span className="text-[10px] text-teal-700 bg-teal-50 px-1.5 py-0.5 rounded font-bold">
                          ID Card
                        </span>
                      </div>
                      {backSrc ? (
                        <div
                          onClick={() => setActiveImagePreview(backSrc)}
                          className="relative aspect-4/3 rounded-lg overflow-hidden bg-slate-100 cursor-pointer group flex items-center justify-center border border-slate-200 shadow-xs"
                        >
                          <img
                            src={backSrc}
                            alt="ID Back"
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                          />
                          <div className="absolute inset-0 bg-slate-950/40 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity text-white font-bold text-xs gap-1.5 backdrop-blur-2xs">
                            <Eye className="w-4 h-4" />
                            გადიდება
                          </div>
                        </div>
                      ) : (
                        <div className="aspect-4/3 rounded-lg border-2 border-dashed border-slate-200 flex flex-col items-center justify-center text-slate-400 bg-white p-4 text-center">
                          <FileText className="w-8 h-8 mb-2 text-slate-300" />
                          <span className="text-xs font-medium text-slate-600">
                            დოკუმენტი არ არის ატვირთული
                          </span>
                          <span className="text-[11px] text-slate-400 mt-0.5">
                            ფერმერს უკანა მხარე არ დაუმატებია
                          </span>
                        </div>
                      )}
                    </div>
                  );
                })()}
              </div>
            </div>

            {/* Actions Inside Modal */}
            <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
              <Button
                variant="outline"
                size="md"
                onClick={() => setSelectedFarmer(null)}
                disabled={isSubmitting}
              >
                დახურვა
              </Button>
              <Button
                variant="danger"
                size="md"
                onClick={() => {
                  setFarmerToReject(selectedFarmer);
                  setRejectReason("");
                }}
                isLoading={
                  submittingFarmerId === selectedFarmer.id &&
                  submittingAction === "REJECTED"
                }
                disabled={isSubmitting}
              >
                <XCircle className="w-4 h-4" />
                დახარვეზება
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={() => setFarmerToApprove(selectedFarmer)}
                isLoading={
                  submittingFarmerId === selectedFarmer.id &&
                  submittingAction === "VERIFIED"
                }
                disabled={isSubmitting}
              >
                <CheckCircle2 className="w-4 h-4" />
                დადასტურება
              </Button>
            </div>
          </div>
        </Modal>
      ) : null}

      {/* Custom Confirmation Modal for Approval */}
      <ConfirmationModal
        isOpen={Boolean(farmerToApprove)}
        onClose={() => setFarmerToApprove(null)}
        onConfirm={async () => {
          if (!farmerToApprove) return;
          const success = await reviewFarmer(farmerToApprove.id, "VERIFIED");
          if (success) {
            setFarmerToApprove(null);
          }
        }}
        title="ფერმერის ვერიფიკაცია"
        message={`ნამდვილად გსურთ ${farmerToApprove?.user.fullName}-ის (${farmerToApprove?.farmName}) ვერიფიცირება? დადასტურების შემდეგ ფერმერს მიენიჭება სრული წვდომა პროდუქციის გამოქვეყნებასა და შეკვეთების მიღებაზე.`}
        confirmText="ვერიფიცირება"
        cancelText="გაუქმება"
        variant="primary"
        isLoading={
          submittingFarmerId === farmerToApprove?.id &&
          submittingAction === "VERIFIED"
        }
      />

      {/* Reject Reason Dialog */}
      <Modal
        isOpen={Boolean(farmerToReject)}
        onClose={() => setFarmerToReject(null)}
        title="ვერიფიკაციის დახარვეზება"
        description={
          farmerToReject
            ? `ფერმერი: ${farmerToReject.user.fullName} (${farmerToReject.farmName}) — მიუთითეთ დახარვეზების მიზეზი`
            : "მიუთითეთ დახარვეზების მიზეზი, რომელიც გაეგზავნება ფერმერს აპლიკაციაში"
        }
        maxWidth="md"
      >
        <div className="space-y-4">
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-700">
              სწრაფი მიზეზები:
            </label>
            <div className="flex flex-wrap gap-2">
              {[
                "ფოტო ბუნდოვანია და არ იკითხება",
                "პირადი ნომერი არ ემთხვევა",
                "მოწმობის ვადა ამოწურულია",
                "ატვირთულია არასწორი დოკუმენტი",
              ].map((reason) => (
                <button
                  key={reason}
                  type="button"
                  onClick={() => setRejectReason(reason)}
                  className={`text-xs px-2.5 py-1.5 rounded-lg border text-left transition-colors ${
                    rejectReason === reason
                      ? "bg-rose-50 border-rose-300 text-rose-800 font-bold"
                      : "bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100"
                  }`}
                >
                  {reason}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="text-xs font-bold text-slate-700 block mb-1">
              დეტალური განმარტება:
            </label>
            <textarea
              rows={3}
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="ჩაწერეთ განმარტება..."
              className="w-full rounded-lg border border-slate-300 p-3 text-sm focus:border-rose-500 focus:ring-1 focus:ring-rose-500 outline-none"
            />
          </div>

          <div className="flex items-center justify-end gap-3 pt-3">
            <Button
              variant="outline"
              size="md"
              onClick={() => setFarmerToReject(null)}
              disabled={isSubmitting}
            >
              გაუქმება
            </Button>
            <Button
              variant="danger"
              size="md"
              onClick={async () => {
                if (!farmerToReject) return;
                const success = await reviewFarmer(
                  farmerToReject.id,
                  "REJECTED",
                  rejectReason || "დოკუმენტი ბუნდოვანია ან არ შეესაბამება მოთხოვნებს"
                );
                if (success) {
                  setFarmerToReject(null);
                  setRejectReason("");
                }
              }}
              isLoading={
                submittingFarmerId === farmerToReject?.id &&
                submittingAction === "REJECTED"
              }
              disabled={isSubmitting}
            >
              დახარვეზების გაგზავნა
            </Button>
          </div>
        </div>
      </Modal>

      {/* Fullscreen Lightbox Image Preview */}
      {activeImagePreview ? (
        <div
          className="fixed inset-0 z-60 bg-black/85 flex items-center justify-center p-4"
          onClick={() => setActiveImagePreview(null)}
        >
          <img
            src={activeImagePreview}
            alt="Preview"
            className="max-w-full max-h-[90vh] rounded-xl object-contain shadow-2xl"
          />
        </div>
      ) : null}
    </div>
  );
};
