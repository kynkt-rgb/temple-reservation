import type { ReactNode } from "react";

type Props = {
  label: string;
  required?: boolean;
  /** label 要素と結びつける入力欄の id（ラジオボタンのまとまりなどでは省略） */
  htmlFor?: string;
  errors?: string[];
  children: ReactNode;
};

/** 項目名・入力欄・エラー（赤字）を1行に並べる */
export function FormField({ label, required, htmlFor, errors, children }: Props) {
  const labelContent = (
    <>
      {label}
      {required && <span className="ml-1 text-red-600">*</span>}
    </>
  );

  return (
    <div className="grid grid-cols-[8rem_1fr] items-start gap-4 py-2">
      {htmlFor ? (
        <label htmlFor={htmlFor} className="pt-2 font-medium">
          {labelContent}
        </label>
      ) : (
        <span className="pt-2 font-medium">{labelContent}</span>
      )}
      <div>
        {children}
        {errors?.map((message) => (
          <p key={message} className="mt-1 text-red-600">
            {message}
          </p>
        ))}
      </div>
    </div>
  );
}
