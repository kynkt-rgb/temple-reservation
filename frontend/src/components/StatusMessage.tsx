/** 読み込み中の表示（基本設計書 8章） */
export function Loading() {
  return <p className="py-8 text-center text-gray-600">読み込み中…</p>;
}

/** 読み込みに失敗したときの表示 */
export function LoadError({ message }: { message: string }) {
  return (
    <p role="alert" className="py-8 text-center text-red-700">
      {message}
    </p>
  );
}
