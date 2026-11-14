"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { LoadError, Loading } from "@/components/StatusMessage";
import { deleteFuneralHold, getFuneralHold, updateFuneralHold } from "@/lib/api";
import { formatDateJa } from "@/lib/date";
import { useApiData } from "@/lib/use-api-data";
import { FuneralHoldForm } from "./FuneralHoldForm";

/** SC-05 葬儀の押さえの編集 */
export function EditFuneralHold() {
  const { id } = useParams<{ id: string }>();
  const { data: record, error, loading } = useApiData(id, getFuneralHold);

  if (loading) return <Loading />;
  if (error || !record) {
    return (
      <div className="text-center">
        <LoadError message={error?.message ?? "指定された予約が見つかりません"} />
        <Link href="/" className="btn-secondary">
          カレンダーに戻る
        </Link>
      </div>
    );
  }

  return (
    <FuneralHoldForm
      key={record.id}
      title="葬儀の押さえの編集"
      submitLabel="更新する"
      notice="updated"
      initial={{ name: record.name, hold_date: record.hold_date, time_slot: record.time_slot, note: record.note ?? "" }}
      save={(input) => updateFuneralHold(record.id, input)}
      deletion={{
        message: `${formatDateJa(record.hold_date)} ${record.time_slot}時 ${record.name} の葬儀の押さえを削除しますか？`,
        run: () => deleteFuneralHold(record.id),
        date: record.hold_date,
      }}
    />
  );
}
