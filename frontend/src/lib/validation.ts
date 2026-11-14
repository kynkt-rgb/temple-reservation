// 画面での入力チェック（基本設計書 5.2）。最終的な判定は API が行う。
// メッセージは API（backend/config/locales/ja.yml）と同じ文にそろえる。
import type { ApiError } from "@/lib/api";
import { isValidDate } from "@/lib/date";
import type { FuneralHoldInput, MemorialServiceInput } from "@/types/api";

/** 項目ごとのエラー */
export type FieldErrors = Partial<Record<string, string[]>>;

/** フォームのエラー。fields は項目の下、form はボタンの上に表示する */
export type FormErrors = { fields: FieldErrors; form: string[] };

export const NO_ERRORS: FormErrors = { fields: {}, form: [] };

export const hasErrors = (errors: FormErrors) =>
  errors.form.length > 0 || Object.values(errors.fields).some((messages) => messages && messages.length > 0);

/** 予約ルール違反。項目の下ではなく、ボタンの上にまとめて表示する（基本設計書 2.5） */
const RULE_CODES = new Set(["slot_taken", "day_taken", "home_requires_sodai", "conflict"]);

/** API のエラーを、項目の下に出すものとボタンの上に出すものに分ける */
export function toFormErrors(error: ApiError): FormErrors {
  const fields: FieldErrors = {};
  const form: string[] = [];
  for (const item of error.errors) {
    if (item.field && !RULE_CODES.has(item.code)) {
      (fields[item.field] ??= []).push(item.message);
    } else {
      form.push(item.message);
    }
  }
  return { fields, form };
}

/** 指定した項目のエラーを除く */
export function omitKeys(fields: FieldErrors, keys: string[]): FieldErrors {
  return Object.fromEntries(Object.entries(fields).filter(([field]) => !keys.includes(field)));
}

function add(fields: FieldErrors, field: string, message: string) {
  (fields[field] ??= []).push(message);
}

export function validateMemorialService(input: MemorialServiceInput): FormErrors {
  const fields: FieldErrors = {};
  const name = input.sponsor_name.trim();
  if (name === "") add(fields, "sponsor_name", "施主の名前を入力してください");
  else if (name.length > 50) add(fields, "sponsor_name", "施主の名前は50文字以内で入力してください");
  if (!isValidDate(input.service_date)) add(fields, "service_date", "日付を入力してください");
  if (input.time_slot === null) add(fields, "time_slot", "時間枠を選んでください");
  if (input.service_type === null) add(fields, "service_type", "法要の種類を選んでください");
  if (input.place === "temple" && input.venue === null) add(fields, "venue", "会場を選んでください");
  if (input.officiant === null) add(fields, "officiant", "担当を選んでください");
  if (input.note.length > 500) add(fields, "note", "備考は500文字以内で入力してください");

  const form: string[] = [];
  if (input.place === "home" && !input.is_sodai) form.push("自宅での法要は総代さんのみ登録できます");
  return { fields, form };
}

export function validateFuneralHold(input: FuneralHoldInput): FormErrors {
  const fields: FieldErrors = {};
  const name = input.name.trim();
  if (name === "") add(fields, "name", "名前を入力してください");
  else if (name.length > 50) add(fields, "name", "名前は50文字以内で入力してください");
  if (!isValidDate(input.hold_date)) add(fields, "hold_date", "日付を入力してください");
  if (input.time_slot === null) add(fields, "time_slot", "時間枠を選んでください");
  if (input.note.length > 500) add(fields, "note", "備考は500文字以内で入力してください");
  return { fields, form: [] };
}
