import { Suspense } from "react";
import { MonthCalendar } from "@/components/calendar/MonthCalendar";
import { Loading } from "@/components/StatusMessage";

/** SC-01 月カレンダー */
export default function CalendarPage() {
  return (
    <Suspense fallback={<Loading />}>
      <MonthCalendar />
    </Suspense>
  );
}
