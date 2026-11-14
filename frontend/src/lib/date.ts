// 日付まわりの処理。日付は "YYYY-MM-DD"、年月は "YYYY-MM" の文字列で扱う
import holidayJp from "@holiday-jp/holiday_jp";

const WEEKDAYS = ["日", "月", "火", "水", "木", "金", "土"] as const;
const MONTH_PATTERN = /^(\d{4})-(0[1-9]|1[0-2])$/;

const pad = (value: number) => String(value).padStart(2, "0");

/** 今日の日付（このPCの時計＝日本時間） */
export function today(): string {
  const now = new Date();
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
}

export const currentMonth = () => today().slice(0, 7);

/** "YYYY-MM" として正しければその値、そうでなければ null */
export function parseMonth(value: string | null): string | null {
  return value && MONTH_PATTERN.test(value) ? value : null;
}

/** 年月を n か月ずらす */
export function addMonths(month: string, n: number): string {
  const [year, mon] = month.split("-").map(Number);
  const date = new Date(year, mon - 1 + n, 1);
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}`;
}

/** その月の日付の一覧 */
export function daysOfMonth(month: string): string[] {
  const [year, mon] = month.split("-").map(Number);
  const count = new Date(year, mon, 0).getDate();
  return Array.from({ length: count }, (_, i) => `${month}-${pad(i + 1)}`);
}

function toDate(date: string): Date {
  const [year, mon, day] = date.split("-").map(Number);
  return new Date(year, mon - 1, day);
}

/** 0=日 … 6=土 */
export const weekdayIndex = (date: string) => toDate(date).getDay();
export const weekdayLabel = (date: string) => WEEKDAYS[weekdayIndex(date)];

/** 祝日なら祝日名、そうでなければ null */
export function holidayName(date: string): string | null {
  const holidays = holidayJp.holidays as Record<string, { name: string } | undefined>;
  return holidays[date]?.name ?? null;
}

/** 例：「2026年11月」 */
export function formatMonthJa(month: string): string {
  const [year, mon] = month.split("-").map(Number);
  return `${year}年${mon}月`;
}

/** 例：「11月20日」 */
export function formatDateJa(date: string): string {
  const [, mon, day] = date.split("-").map(Number);
  return `${mon}月${day}日`;
}

/** 例：「2026/11/20（金）」 */
export function formatDateWithWeekday(date: string): string {
  return `${date.replaceAll("-", "/")}（${weekdayLabel(date)}）`;
}

/** "YYYY-MM-DD" として正しい日付なら true */
export function isValidDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = toDate(value);
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` === value;
}
