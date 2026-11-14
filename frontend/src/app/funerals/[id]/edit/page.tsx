import type { Metadata } from "next";
import { Suspense } from "react";
import { EditFuneralHold } from "@/components/funerals/EditFuneralHold";
import { Loading } from "@/components/StatusMessage";

export const metadata: Metadata = { title: "葬儀の押さえの編集 | 法要予約管理" };

/** SC-05 葬儀の押さえの編集 */
export default function EditFuneralHoldPage() {
  return (
    <Suspense fallback={<Loading />}>
      <EditFuneralHold />
    </Suspense>
  );
}
