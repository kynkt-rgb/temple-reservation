"use client";

import { useSearchParams } from "next/navigation";
import { parseSlot } from "@/constants/options";
import { createMemorialService } from "@/lib/api";
import { isValidDate } from "@/lib/date";
import { useVisitCount } from "@/lib/use-visit-count";
import { EMPTY_MEMORIAL_SERVICE, MemorialServiceForm } from "./MemorialServiceForm";

/** SC-02 法要予約の登録。カレンダーから開いたときは日付・時間枠が入った状態にする */
export function NewMemorialService() {
  const searchParams = useSearchParams();
  const date = searchParams.get("date") ?? "";
  // 開くたび（日付・時間枠が変わったときも）入力内容を初期値に戻す
  const visit = useVisitCount();

  return (
    <MemorialServiceForm
      key={`${visit}:${searchParams.toString()}`}
      title="法要予約の登録"
      submitLabel="登録する"
      notice="created"
      initial={{
        ...EMPTY_MEMORIAL_SERVICE,
        service_date: isValidDate(date) ? date : "",
        time_slot: parseSlot(searchParams.get("slot")),
      }}
      save={createMemorialService}
    />
  );
}
