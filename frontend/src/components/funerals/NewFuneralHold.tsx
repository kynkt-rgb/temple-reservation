"use client";

import { useSearchParams } from "next/navigation";
import { parseSlot } from "@/constants/options";
import { createFuneralHold } from "@/lib/api";
import { isValidDate } from "@/lib/date";
import { EMPTY_FUNERAL_HOLD, FuneralHoldForm } from "./FuneralHoldForm";

/** SC-04 葬儀の押さえの登録。カレンダーから開いたときは日付・時間枠が入った状態にする */
export function NewFuneralHold() {
  const searchParams = useSearchParams();
  const date = searchParams.get("date") ?? "";

  return (
    <FuneralHoldForm
      // 日付・時間枠が変わったら、初期値からフォームを作り直す
      key={searchParams.toString()}
      title="葬儀の押さえ"
      submitLabel="登録する"
      notice="created"
      initial={{
        ...EMPTY_FUNERAL_HOLD,
        hold_date: isValidDate(date) ? date : "",
        time_slot: parseSlot(searchParams.get("slot")),
      }}
      save={createFuneralHold}
    />
  );
}
