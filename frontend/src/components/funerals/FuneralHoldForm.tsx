"use client";

import { useRouter } from "next/navigation";
import { useId, useState } from "react";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { FormErrorList } from "@/components/form/FormErrorList";
import { FormField } from "@/components/form/FormField";
import { RadioGroup } from "@/components/form/RadioGroup";
import { TIME_SLOTS } from "@/constants/options";
import { toApiError } from "@/lib/api";
import { calendarUrl, type NoticeKey } from "@/lib/navigation";
import { useGoBack } from "@/lib/use-go-back";
import { hasErrors, NO_ERRORS, omitKeys, toFormErrors, validateFuneralHold, type FormErrors } from "@/lib/validation";
import type { FuneralHold, FuneralHoldInput } from "@/types/api";

const SLOT_OPTIONS = TIME_SLOTS.map((slot) => ({ value: slot as number, label: `${slot}時` }));

export const EMPTY_FUNERAL_HOLD: FuneralHoldInput = { name: "", hold_date: "", time_slot: null, note: "" };

type Props = {
  title: string;
  initial: FuneralHoldInput;
  submitLabel: string;
  notice: NoticeKey;
  save: (input: FuneralHoldInput) => Promise<FuneralHold>;
  /** 編集画面のみ：削除の確認文と処理 */
  deletion?: { message: string; run: () => Promise<void>; date: string };
};

/** 葬儀の押さえの登録・編集フォーム（基本設計書 2.6） */
export function FuneralHoldForm({ title, initial, submitLabel, notice, save, deletion }: Props) {
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

  const update = (changes: Partial<FuneralHoldInput>) => {
    setInput((prev) => ({ ...prev, ...changes }));
    // 直した項目のエラーと、ボタンの上のエラーは消す（次の送信でもう一度チェックする）
    setErrors((prev) => ({ fields: omitKeys(prev.fields, Object.keys(changes)), form: [] }));
  };

  const handleSubmit = async () => {
    const found = validateFuneralHold(input);
    setErrors(found);
    if (hasErrors(found)) return;

    setSaving(true);
    try {
      const saved = await save(input);
      reset();
      router.push(calendarUrl(saved.hold_date, notice));
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
        <FormField label="名前" required htmlFor={idOf("name")} errors={errors.fields.name}>
          <input
            id={idOf("name")}
            className="input w-80"
            maxLength={50}
            placeholder="例：鈴木家"
            value={input.name}
            onChange={(event) => update({ name: event.target.value })}
          />
        </FormField>

        <FormField label="日付" required htmlFor={idOf("hold_date")} errors={errors.fields.hold_date}>
          <input
            id={idOf("hold_date")}
            type="date"
            className="input"
            value={input.hold_date}
            onChange={(event) => update({ hold_date: event.target.value })}
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

        <FormField label="備考" htmlFor={idOf("note")} errors={errors.fields.note}>
          <textarea
            id={idOf("note")}
            rows={3}
            className="input w-full"
            maxLength={500}
            value={input.note}
            onChange={(event) => update({ note: event.target.value })}
          />
        </FormField>

        <FormErrorList messages={errors.form} />

        <div className="mt-6 flex items-center gap-3">
          {deletion && (
            <button type="button" className="btn-danger-outline" onClick={() => setConfirming(true)} disabled={saving}>
              この押さえを削除
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
