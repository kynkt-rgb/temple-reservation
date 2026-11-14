"use client";

import { useLayoutEffect, useState } from "react";

/**
 * 画面が表示されるたびに増える番号。
 *
 * Cache Components が有効な Next.js では、画面を移っても前の画面は消えずに隠れるだけで、
 * 戻ったときに state（取得したデータ・入力内容・メニューの開閉）がそのまま残る。
 * 隠れるときに番号を増やし、データの再取得やフォームの作り直しのきっかけにする。
 * （node_modules/next/dist/docs/01-app/02-guides/preserving-ui-state.md）
 */
export function useVisitCount(): number {
  const [visit, setVisit] = useState(0);
  useLayoutEffect(() => {
    return () => setVisit((count) => count + 1);
  }, []);
  return visit;
}
