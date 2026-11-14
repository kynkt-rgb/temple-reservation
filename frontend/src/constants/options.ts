// 選択肢の値と表示名（基本設計書 3.4）
import type { Officiant, Place, ServiceType } from "@/types/api";

export type Option<T> = { value: T; label: string };

/** 時間枠の開始時刻（10〜15時） */
export const TIME_SLOTS = [10, 11, 12, 13, 14, 15] as const;

/** 文字列の時間枠が 10〜15 なら数値、そうでなければ null */
export function parseSlot(value: string | null): number | null {
  const slot = Number(value);
  return (TIME_SLOTS as readonly number[]).includes(slot) ? slot : null;
}

export const SERVICE_TYPE_OPTIONS: Option<ServiceType>[] = [
  { value: "shijukunichi", label: "四十九日" },
  { value: "isshuki", label: "一周忌" },
  { value: "sankaiki", label: "三回忌" },
  { value: "nanakaiki", label: "七回忌" },
  { value: "jusankaiki", label: "十三回忌" },
  { value: "jushichikaiki", label: "十七回忌" },
  { value: "nijusankaiki", label: "二十三回忌" },
  { value: "nijushichikaiki", label: "二十七回忌" },
  { value: "sanjusankaiki", label: "三十三回忌" },
  { value: "gojukkaiki", label: "五十回忌" },
  { value: "other", label: "その他" },
];

export const PLACE_OPTIONS: Option<Place>[] = [
  { value: "temple", label: "お寺" },
  { value: "home", label: "自宅" },
];

/** 担当は任意。指定なし（null）は「2人で対応」を表す（法要は基本2人で行うため） */
export const OFFICIANT_OPTIONS: Option<Officiant | null>[] = [
  { value: null, label: "指定なし（2人）" },
  { value: "jushoku", label: "住職" },
  { value: "fukujushoku", label: "副住職" },
];

/** 一覧などに出す担当の表示名。指定なしは「2人」 */
export function officiantLabel(value: Officiant | null): string {
  return value === null ? "2人" : labelOf(OFFICIANT_OPTIONS, value);
}

/** カレンダーのセル用の短い表示名 */
export function officiantShortLabel(value: Officiant | null): string {
  return { jushoku: "住職", fukujushoku: "副住", none: "2人" }[value ?? "none"];
}

function labelOf<T>(options: Option<T>[], value: T | null): string {
  return options.find((option) => option.value === value)?.label ?? "";
}

export const serviceTypeLabel = (value: ServiceType | null) => labelOf(SERVICE_TYPE_OPTIONS, value);
export const placeLabel = (value: Place | null) => labelOf(PLACE_OPTIONS, value);
