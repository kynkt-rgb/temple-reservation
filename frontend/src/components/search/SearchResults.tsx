"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { LoadError, Loading } from "@/components/StatusMessage";
import { officiantLabel, placeLabel, serviceTypeLabel } from "@/constants/options";
import { searchMemorialServices } from "@/lib/api";
import { formatDateWithWeekday } from "@/lib/date";
import { useApiData } from "@/lib/use-api-data";

/** SC-06 施主名検索（基本設計書 2.7）。法要予約だけを、日付の新しい順に表示する */
export function SearchResults() {
  const router = useRouter();
  const keyword = (useSearchParams().get("name") ?? "").trim();
  const { data, error, loading } = useApiData(keyword === "" ? null : keyword, searchMemorialServices);

  if (keyword === "") {
    return (
      <p role="alert" className="py-8 text-center text-red-700">
        施主名を入力してください
      </p>
    );
  }
  if (loading) return <Loading />;
  if (error) return <LoadError message={error.message} />;
  if (!data) return null;

  const results = data.memorial_services;
  return (
    <section>
      <h1 className="mb-4 text-2xl font-bold">
        「{keyword}」の検索結果（{results.length}件）
      </h1>
      {data.truncated && (
        <p className="mb-2 text-gray-700">該当が多いため、新しい順に{results.length}件を表示しています。</p>
      )}
      {results.length === 0 ? (
        <p className="py-8 text-center text-gray-700">該当する予約はありません</p>
      ) : (
        <table className="w-full border-collapse bg-white">
          <thead className="bg-gray-100">
            <tr>
              {["日付", "時間枠", "施主名", "法要", "場所", "担当"].map((heading) => (
                <th key={heading} className="border border-gray-300 px-3 py-2 text-left">
                  {heading}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {results.map((service) => {
              const href = `/services/${service.id}/edit`;
              return (
                <tr key={service.id} className="cursor-pointer hover:bg-sky-50" onClick={() => router.push(href)}>
                  <td className="border border-gray-300 px-3 py-2">{formatDateWithWeekday(service.service_date)}</td>
                  <td className="border border-gray-300 px-3 py-2">{service.time_slot}時</td>
                  <td className="border border-gray-300 px-3 py-2">
                    <Link href={href} className="text-sky-800 underline">
                      {service.sponsor_name}
                    </Link>
                  </td>
                  <td className="border border-gray-300 px-3 py-2">{serviceTypeLabel(service.service_type)}</td>
                  <td className="border border-gray-300 px-3 py-2">{placeLabel(service.place)}</td>
                  <td className="border border-gray-300 px-3 py-2">{officiantLabel(service.officiant)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </section>
  );
}
