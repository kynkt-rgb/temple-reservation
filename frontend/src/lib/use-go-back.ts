"use client";

import { useRouter } from "next/navigation";

/** 「キャンセル」：直前の画面に戻る。直接開いた画面ならカレンダーへ（基本設計書 2.2） */
export function useGoBack() {
  const router = useRouter();
  return () => {
    if (window.history.length > 1) router.back();
    else router.push("/");
  };
}
