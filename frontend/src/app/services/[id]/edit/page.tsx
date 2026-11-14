import type { Metadata } from "next";
import { Suspense } from "react";
import { EditMemorialService } from "@/components/services/EditMemorialService";
import { Loading } from "@/components/StatusMessage";

export const metadata: Metadata = { title: "法要予約の編集 | 法要予約管理" };

/** SC-03 法要予約の編集 */
export default function EditMemorialServicePage() {
  return (
    <Suspense fallback={<Loading />}>
      <EditMemorialService />
    </Suspense>
  );
}
