import type { Metadata } from "next";
import { Suspense } from "react";
import { SearchResults } from "@/components/search/SearchResults";
import { Loading } from "@/components/StatusMessage";

export const metadata: Metadata = { title: "施主名検索 | 法要予約管理" };

/** SC-06 施主名検索 */
export default function SearchPage() {
  return (
    <Suspense fallback={<Loading />}>
      <SearchResults />
    </Suspense>
  );
}
