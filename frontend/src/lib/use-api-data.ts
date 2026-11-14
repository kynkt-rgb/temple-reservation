"use client";

import { useEffect, useState } from "react";
import { ApiError, toApiError } from "@/lib/api";
import { useVisitCount } from "@/lib/use-visit-count";

type Result<T> = { requestKey: string; data?: T; error?: ApiError };

/**
 * param が変わるたび、または画面が再表示されるたびに load(param) を呼び、結果を返す。
 * 再表示のたびに取り直すので、ほかの画面で登録・更新した内容がすぐ反映される。
 * load はモジュールで定義した関数（getCalendar など）を渡す。
 */
export function useApiData<T>(param: string | null, load: (param: string) => Promise<T>) {
  const visit = useVisitCount();
  const requestKey = param === null ? null : `${visit}:${param}`;
  const [result, setResult] = useState<Result<T> | null>(null);

  useEffect(() => {
    if (param === null || requestKey === null) return;
    let cancelled = false;
    load(param).then(
      (data) => {
        if (!cancelled) setResult({ requestKey, data });
      },
      (error: unknown) => {
        if (!cancelled) setResult({ requestKey, error: toApiError(error) });
      },
    );
    return () => {
      cancelled = true;
    };
  }, [param, requestKey, load]);

  const current = requestKey !== null && result?.requestKey === requestKey ? result : null;
  return {
    data: current?.data,
    error: current?.error,
    loading: requestKey !== null && current === null,
  };
}
