"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { LoadError, Loading } from "@/components/StatusMessage";
import { serviceTypeLabel } from "@/constants/options";
import { deleteMemorialService, getMemorialService, updateMemorialService } from "@/lib/api";
import { formatDateJa } from "@/lib/date";
import { useApiData } from "@/lib/use-api-data";
import type { MemorialService, MemorialServiceInput } from "@/types/api";
import { MemorialServiceForm } from "./MemorialServiceForm";

function toInput(record: MemorialService): MemorialServiceInput {
  return { ...record, note: record.note ?? "" };
}

/** SC-03 法要予約の編集 */
export function EditMemorialService() {
  const { id } = useParams<{ id: string }>();
  const { data: record, error, loading } = useApiData(id, getMemorialService);

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
    <MemorialServiceForm
      key={record.id}
      title="法要予約の編集"
      submitLabel="更新する"
      notice="updated"
      initial={toInput(record)}
      save={(input) => updateMemorialService(record.id, input)}
      deletion={{
        // 例：「11月20日 10時 山田太郎様 一周忌 を削除しますか？」
        message: `${formatDateJa(record.service_date)} ${record.time_slot}時 ${record.sponsor_name}様 ${serviceTypeLabel(record.service_type)} を削除しますか？`,
        run: () => deleteMemorialService(record.id),
        date: record.service_date,
      }}
    />
  );
}
