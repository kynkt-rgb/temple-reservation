import type { Option } from "@/constants/options";

type Props<T extends string | number | boolean | null> = {
  name: string;
  /** 読み上げ用のまとまりの名前 */
  label: string;
  options: Option<T>[];
  value: T | null;
  onChange: (value: T) => void;
  disabled?: boolean;
  /** 個別に選べなくする選択肢 */
  isOptionDisabled?: (value: T) => boolean;
};

export function RadioGroup<T extends string | number | boolean | null>({
  name,
  label,
  options,
  value,
  onChange,
  disabled,
  isOptionDisabled,
}: Props<T>) {
  return (
    <div role="radiogroup" aria-label={label} className="flex flex-wrap gap-x-6 gap-y-2 pt-2">
      {options.map((option) => {
        const optionDisabled = disabled || isOptionDisabled?.(option.value);
        return (
          <label
            key={String(option.value)}
            className={`inline-flex items-center gap-2 ${optionDisabled ? "cursor-not-allowed text-gray-400" : "cursor-pointer"}`}
          >
            <input
              type="radio"
              name={name}
              className="size-4"
              checked={value === option.value}
              disabled={optionDisabled}
              onChange={() => onChange(option.value)}
            />
            {option.label}
          </label>
        );
      })}
    </div>
  );
}
