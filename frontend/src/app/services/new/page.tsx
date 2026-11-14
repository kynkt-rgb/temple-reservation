import type { Metadata } from "next";
import { Suspense } from "react";
import { NewMemorialService } from "@/components/services/NewMemorialService";
import { Loading } from "@/components/StatusMessage";

export const metadata: Metadata = { title: "法要予約の登録 | 法要予約管理" };

/** SC-02 法要予約の登録 */
export default function NewMemorialServicePage() {
  return (
    <Suspense fallback={<Loading />}>
      <NewMemorialService />
    </Suspense>
  );
}
