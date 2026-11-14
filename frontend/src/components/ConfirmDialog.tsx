"use client";

import { useEffect, useRef } from "react";

type Props = {
  open: boolean;
  message: string;
  confirmLabel: string;
  cancelLabel?: string;
  busy?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
};

/** 削除の確認などに使うダイアログ */
export function ConfirmDialog({ open, message, confirmLabel, cancelLabel = "やめる", busy, onConfirm, onCancel }: Props) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) dialog.showModal();
    if (!open && dialog.open) dialog.close();
  }, [open]);

  return (
    <dialog
      ref={ref}
      onCancel={(event) => {
        // Esc キーで閉じるときも onCancel を通す
        event.preventDefault();
        if (!busy) onCancel();
      }}
      className="m-auto rounded-lg p-6 shadow-xl backdrop:bg-black/40"
    >
      <p className="mb-6 text-lg">{message}</p>
      <div className="flex justify-end gap-3">
        <button type="button" className="btn-secondary" onClick={onCancel} disabled={busy}>
          {cancelLabel}
        </button>
        <button type="button" className="btn-danger" onClick={onConfirm} disabled={busy}>
          {busy ? "処理中…" : confirmLabel}
        </button>
      </div>
    </dialog>
  );
}
