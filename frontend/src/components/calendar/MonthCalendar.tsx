"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useLayoutEffect, useMemo, useState } from "react";
import { LoadError, Loading } from "@/components/StatusMessage";
import { TIME_SLOTS } from "@/constants/options";
import { getCalendar } from "@/lib/api";
import {
  addMonths,
  currentMonth,
  daysOfMonth,
  formatMonthJa,
  holidayName,
  parseMonth,
  today,
  weekdayIndex,
  weekdayLabel,
} from "@/lib/date";
import { isNoticeKey, NOTICES } from "@/lib/navigation";
import { useApiData } from "@/lib/use-api-data";
import type { CalendarResponse, FuneralHold, MemorialService } from "@/types/api";
import { CalendarCell } from "./CalendarCell";

const NOTICE_MILLISECONDS = 4000;

const cellKey = (date: string, slot: number) => `${date}_${slot}`;

/** 日付と時間枠ごとに、法要と葬儀の押さえを引けるようにする */
function indexCalendar(data: CalendarResponse | undefined) {
  const services = new Map<string, MemorialService>();
  const funerals = new Map<string, FuneralHold>();
  const funeralDates = new Set<string>();
  for (const service of data?.memorial_services ?? []) {
    services.set(cellKey(service.service_date, service.time_slot), service);
  }
  for (const hold of data?.funeral_holds ?? []) {
    funerals.set(cellKey(hold.hold_date, hold.time_slot), hold);
    funeralDates.add(hold.hold_date);
  }
  return { services, funerals, funeralDates };
}

/** 曜日・祝日の文字色（土曜は青、日曜・祝日は赤） */
function dayColor(date: string): string {
  if (weekdayIndex(date) === 0 || holidayName(date)) return "text-red-600";
  if (weekdayIndex(date) === 6) return "text-blue-600";
  return "";
}

/** SC-01 月カレンダー（基本設計書 2.4）：縦に日付、横に時間枠 */
export function MonthCalendar() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const month = parseMonth(searchParams.get("month")) ?? currentMonth();
  const notice = searchParams.get("notice");

  const { data, error, loading } = useApiData(month, getCalendar);
  const { services, funerals, funeralDates } = useMemo(() => indexCalendar(data), [data]);
  const [openMenu, setOpenMenu] = useState<string | null>(null);
  const todayDate = today();

  // ほかの画面へ移るときにメニューを閉じる（戻ったときに開いたままにしない）
  useLayoutEffect(() => {
    return () => setOpenMenu(null);
  }, []);

  // お知らせは数秒後に消す（URL から notice を外す）
  useEffect(() => {
    if (!isNoticeKey(notice)) return;
    const timer = setTimeout(() => router.replace(`/?month=${month}`, { scroll: false }), NOTICE_MILLISECONDS);
    return () => clearTimeout(timer);
  }, [notice, month, router]);

  return (
    <section>
      {isNoticeKey(notice) && (
        <p role="status" className="mb-4 rounded border border-green-300 bg-green-50 px-4 py-2 text-green-800">
          {NOTICES[notice]}
        </p>
      )}

      <nav className="mb-4 flex items-center justify-center gap-6">
        <Link href={`/?month=${addMonths(month, -1)}`} className="btn-secondary">
          ◀ 前月
        </Link>
        <h1 className="w-40 text-center text-2xl font-bold">{formatMonthJa(month)}</h1>
        <Link href={`/?month=${addMonths(month, 1)}`} className="btn-secondary">
          翌月 ▶
        </Link>
        <Link href="/" className="btn-secondary">
          今月
        </Link>
      </nav>

      {loading && <Loading />}
      {error && <LoadError message={error.message} />}
      {data && (
        <table className="w-full table-fixed border-collapse bg-white text-sm">
          <thead className="sticky top-0 z-10 bg-gray-100">
            <tr>
              <th className="w-24 border border-gray-300 px-2 py-2">日付</th>
              {TIME_SLOTS.map((slot) => (
                <th key={slot} className="border border-gray-300 px-2 py-2">
                  {slot}時
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {daysOfMonth(month).map((date) => {
              const holiday = holidayName(date);
              const isToday = date === todayDate;
              return (
                <tr key={date} className={isToday ? "bg-amber-50" : undefined}>
                  <th
                    scope="row"
                    className={`border border-gray-300 px-2 py-1 text-left font-medium ${dayColor(date)}`}
                    title={holiday ?? undefined}
                  >
                    <span className="text-base">{Number(date.slice(8))}</span> {weekdayLabel(date)}
                    {holiday && <span className="block truncate text-xs">{holiday}</span>}
                    {isToday && <span className="block text-xs text-amber-700">今日</span>}
                  </th>
                  {TIME_SLOTS.map((slot) => {
                    const key = cellKey(date, slot);
                    return (
                      <CalendarCell
                        key={key}
                        date={date}
                        slot={slot}
                        service={services.get(key)}
                        funeral={funerals.get(key)}
                        dayHasFuneral={funeralDates.has(date)}
                        menuOpen={openMenu === key}
                        onOpenMenu={() => setOpenMenu(openMenu === key ? null : key)}
                        onCloseMenu={() => setOpenMenu(null)}
                      />
                    );
                  })}
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </section>
  );
}
