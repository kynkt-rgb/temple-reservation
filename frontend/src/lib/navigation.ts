// 画面遷移のお知らせ（基本設計書 2.2：成功したらカレンダーに戻り、お知らせを表示する）

export const NOTICES = {
  created: "登録しました",
  updated: "更新しました",
  deleted: "削除しました",
} as const;

export type NoticeKey = keyof typeof NOTICES;

export function isNoticeKey(value: string | null): value is NoticeKey {
  return value !== null && value in NOTICES;
}

/** その日付の月のカレンダーへの URL */
export function calendarUrl(date: string, notice?: NoticeKey): string {
  const params = new URLSearchParams({ month: date.slice(0, 7) });
  if (notice) params.set("notice", notice);
  return `/?${params.toString()}`;
}
