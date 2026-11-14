"use client";

import { useEffect, useLayoutEffect, useState } from "react";
import { ApiError, toApiError } from "@/lib/api";

type Result<T> = { param: string; data?: T; error?: ApiError };

/**
 * param が変わるたび、または画面が再表示されるたびに load(param) を呼び、結果を返す。
 *
 * Cache Components が有効な Next.js では、画面を移っても前の画面は隠れて残る（React の Activity）。
 * 隠れるときに取得済みのデータを捨て、再表示で effect が再実行されたときに取り直すので、
 * ほかの画面で登録・更新した内容がすぐ反映され、古いデータが一瞬表示されることもない。
 * （node_modules/next/dist/docs/01-app/02-guides/preserving-ui-state.md）
 *
 * load はモジュールで定義した関数（getCalendar など）を渡す。
 */
export function useApiData<T>(param: string | null, load: (param: string) => Promise<T>) {
  const [result, setResult] = useState<Result<T> | null>(null);

  // 画面が隠れるときに、取得済みのデータを捨てる
  useLayoutEffect(() => {
    return () => setResult(null);
  }, []);

  // 表示されたとき・param が変わったときに取得する
  useEffect(() => {
    if (param === null) return;
    let cancelled = false;
    load(param).then(
      (data) => {
        if (!cancelled) setResult({ param, data });
      },
      (error: unknown) => {
        if (!cancelled) setResult({ param, error: toApiError(error) });
      },
    );
    return () => {
      cancelled = true;
    };
  }, [param, load]);

  const current = param !== null && result?.param === param ? result : null;
  return {
    data: current?.data,
    error: current?.error,
    loading: param !== null && current === null,
  };
}
