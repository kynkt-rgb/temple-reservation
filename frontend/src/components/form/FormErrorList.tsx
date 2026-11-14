/** ボタンの上に出すエラー（予約ルール違反・通信エラーなど） */
export function FormErrorList({ messages }: { messages: string[] }) {
  if (messages.length === 0) return null;
  return (
    <div role="alert" className="my-4 rounded border border-red-300 bg-red-50 px-4 py-3 text-red-700">
      {messages.map((message) => (
        <p key={message}>{message}</p>
      ))}
    </div>
  );
}
