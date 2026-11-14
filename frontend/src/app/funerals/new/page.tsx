import type { Metadata } from "next";
import { Suspense } from "react";
import { NewFuneralHold } from "@/components/funerals/NewFuneralHold";
import { Loading } from "@/components/StatusMessage";

export const metadata: Metadata = { title: "葬儀の押さえ | 法要予約管理" };

/** SC-04 葬儀の押さえの登録 */
export default function NewFuneralHoldPage() {
  return (
    <Suspense fallback={<Loading />}>
      <NewFuneralHold />
    </Suspense>
  );
}
