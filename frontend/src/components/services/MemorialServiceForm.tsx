"use client";

import { useRouter } from "next/navigation";
import { useId, useState } from "react";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { FormErrorList } from "@/components/form/FormErrorList";
import { FormField } from "@/components/form/FormField";
import { RadioGroup } from "@/components/form/RadioGroup";
import { OFFICIANT_OPTIONS, PLACE_OPTIONS, SERVICE_TYPE_OPTIONS, TIME_SLOTS } from "@/constants/options";
import { toApiError } from "@/lib/api";
import { calendarUrl, type NoticeKey } from "@/lib/navigation";
import { useGoBack } from "@/lib/use-go-back";
import { hasErrors, NO_ERRORS, omitKeys, toFormErrors, validateMemorialService, type FormErrors } from "@/lib/validation";
import type { MemorialService, MemorialServiceInput, ServiceType } from "@/types/api";

const SLOT_OPTIONS = TIME_SLOTS.map((slot) => ({ value: slot as number, label: `${slot}時` }));
const MEAL_OPTIONS = [
  { value: true, label: "する" },
  { value: false, label: "しない" },
];

export const EMPTY_MEMORIAL_SERVICE: MemorialServiceInput = {
  sponsor_name: "",
  service_date: "",
  time_slot: null,
  service_type: null,
  is_sodai: false,
  place: "temple",
  has_meal: false,
  officiant: null,
  note: "",
};

type Props = {
  title: string;
  initial: MemorialServiceInput;
  submitLabel: string;
  notice: NoticeKey;
  save: (input: MemorialServiceInput) => Promise<MemorialService>;
  /** 編集画面のみ：削除の確認文と処理 */
  deletion?: { message: string; run: () => Promise<void>; date: string };
};

/** 法要予約の登録・編集フォーム（基本設計書 2.5） */
export function MemorialServiceForm({ title, initial, submitLabel, notice, save, deletion }: Props) {
  const router = useRouter();
  const goBack = useGoBack();
  // 画面が隠れて残っても id が重ならないよう、フォームごとに違う id にする
  const idPrefix = useId();
  const idOf = (field: string) => `${idPrefix}-${field}`;
  const [input, setInput] = useState(initial);
  const [errors, setErrors] = useState<FormErrors>(NO_ERRORS);
  const [saving, setSaving] = useState(false);
  const [confirming, setConfirming] = useState(false);
  const [deleting, setDeleting] = useState(false);

  // 画面は隠れて残るため、保存・削除・キャンセルで離れるときは入力内容を初期値に戻す。
  // 次にこの画面を開いたとき、前の入力が残らないようにする（preserving-ui-state.md）
  const reset = () => {
    setInput(initial);
    setErrors(NO_ERRORS);
    setSaving(false);
    setConfirming(false);
    setDeleting(false);
  };

  const update = (changes: Partial<MemorialServiceInput>) => {
    setInput((prev) => ({ ...prev, ...changes }));
    // 直した項目のエラーと、ボタンの上のエラーは消す（次の送信でもう一度チェックする）
    setErrors((prev) => ({ fields: omitKeys(prev.fields, Object.keys(changes)), form: [] }));
  };

  const handleSubmit = async () => {
    const found = validateMemorialService(input);
    setErrors(found);
    if (hasErrors(found)) return;

    setSaving(true);
    try {
      const saved = await save(input);
      reset();
      router.push(calendarUrl(saved.service_date, notice));
    } catch (error) {
      setErrors(toFormErrors(toApiError(error)));
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deletion) return;
    setDeleting(true);
    try {
      await deletion.run();
      reset();
      router.push(calendarUrl(deletion.date, "deleted"));
    } catch (error) {
      setErrors(toFormErrors(toApiError(error)));
      setDeleting(false);
      setConfirming(false);
    }
  };

  return (
    <section className="mx-auto max-w-3xl">
      <h1 className="mb-4 text-2xl font-bold">{title}</h1>
      <form
        noValidate
        className="rounded-lg border border-gray-300 bg-white px-8 py-6"
        onSubmit={(event) => {
          event.preventDefault();
          void handleSubmit();
        }}
      >
        <FormField label="施主の名前" required htmlFor={idOf("sponsor_name")} errors={errors.fields.sponsor_name}>
          <input
            id={idOf("sponsor_name")}
            className="input w-80"
            maxLength={50}
            value={input.sponsor_name}
            onChange={(event) => update({ sponsor_name: event.target.value })}
          />
        </FormField>

        <FormField label="日付" required htmlFor={idOf("service_date")} errors={errors.fields.service_date}>
          <input
            id={idOf("service_date")}
            type="date"
            className="input"
            value={input.service_date}
            onChange={(event) => update({ service_date: event.target.value })}
          />
        </FormField>

        <FormField label="時間枠" required errors={errors.fields.time_slot}>
          <RadioGroup
            name="time_slot"
            label="時間枠"
            options={SLOT_OPTIONS}
            value={input.time_slot}
            onChange={(time_slot) => update({ time_slot })}
          />
        </FormField>

        <FormField label="法要の種類" required htmlFor={idOf("service_type")} errors={errors.fields.service_type}>
          <select
            id={idOf("service_type")}
            className="input w-56"
            value={input.service_type ?? ""}
            onChange={(event) => update({ service_type: (event.target.value || null) as ServiceType | null })}
          >
            <option value="">選んでください</option>
            {SERVICE_TYPE_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </FormField>

        <FormField label="総代" required errors={errors.fields.is_sodai}>
          <label className="inline-flex cursor-pointer items-center gap-2 pt-2">
            <input
              type="checkbox"
              className="size-4"
              checked={input.is_sodai}
              onChange={(event) => {
                const isSodai = event.target.checked;
                // 総代でなくなったら、場所はお寺に戻す（R-6）
                update(isSodai || input.place === "temple" ? { is_sodai: isSodai } : { is_sodai: false, place: "temple" });
              }}
            />
            施主は総代さん
          </label>
        </FormField>

        <FormField label="場所" required errors={errors.fields.place}>
          <RadioGroup
            name="place"
            label="場所"
            options={PLACE_OPTIONS}
            value={input.place}
            // 自宅は総代さんのみ（R-6）
            isOptionDisabled={(place) => place === "home" && !input.is_sodai}
            onChange={(place) => update({ place })}
          />
          {!input.is_sodai && <p className="mt-1 text-sm text-gray-600">自宅は総代さんのみ選べます</p>}
        </FormField>

        <FormField label="食事" required errors={errors.fields.has_meal}>
          <div className="flex flex-wrap items-center gap-x-6">
            <span className="pt-2">法要後に食事をしますか？</span>
            <RadioGroup
              name="has_meal"
              label="法要後に食事をしますか？"
              options={MEAL_OPTIONS}
              value={input.has_meal}
              onChange={(has_meal) => update({ has_meal })}
            />
          </div>
        </FormField>

        <FormField label="担当" required errors={errors.fields.officiant}>
          <RadioGroup
            name="officiant"
            label="担当"
            options={OFFICIANT_OPTIONS}
            value={input.officiant}
            onChange={(officiant) => update({ officiant })}
          />
        </FormField>

        <FormField label="備考" htmlFor={idOf("note")} errors={errors.fields.note}>
          <textarea
            id={idOf("note")}
            rows={3}
            className="input w-full"
            maxLength={500}
            placeholder="故人名・連絡先・人数・仕出し先など"
            value={input.note}
            onChange={(event) => update({ note: event.target.value })}
          />
        </FormField>

        <FormErrorList messages={errors.form} />

        <div className="mt-6 flex items-center gap-3">
          {deletion && (
            <button type="button" className="btn-danger-outline" onClick={() => setConfirming(true)} disabled={saving}>
              この予約を削除
            </button>
          )}
          <div className="ml-auto flex gap-3">
            <button type="button" className="btn-secondary" onClick={() => {
                reset();
                goBack();
              }}
              disabled={saving}
            >
              キャンセル
            </button>
            <button type="submit" className="btn-primary" disabled={saving}>
              {saving ? "保存中…" : submitLabel}
            </button>
          </div>
        </div>
      </form>

      {deletion && (
        <ConfirmDialog
          open={confirming}
          message={deletion.message}
          confirmLabel="削除する"
          busy={deleting}
          onConfirm={() => void handleDelete()}
          onCancel={() => setConfirming(false)}
        />
      )}
    </section>
  );
}
