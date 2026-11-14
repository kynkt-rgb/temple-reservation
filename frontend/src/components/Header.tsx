"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";

/** 共通ヘッダー（基本設計書 2.3） */
export function Header() {
  const router = useRouter();
  const [keyword, setKeyword] = useState("");

  return (
    <header className="border-b border-gray-300 bg-white">
      <div className="mx-auto flex max-w-7xl items-center gap-8 px-6 py-3">
        <Link href="/" className="text-xl font-bold">
          法要予約管理
        </Link>
        <Link href="/" className="btn-secondary">
          カレンダー
        </Link>
        <form
          role="search"
          className="ml-auto flex items-center gap-2"
          onSubmit={(event) => {
            event.preventDefault();
            router.push(`/search?${new URLSearchParams({ name: keyword.trim() }).toString()}`);
          }}
        >
          <label htmlFor="header-search">施主名で検索</label>
          <input
            id="header-search"
            type="search"
            className="input w-56"
            value={keyword}
            onChange={(event) => setKeyword(event.target.value)}
          />
          <button type="submit" className="btn-primary">
            検索
          </button>
        </form>
      </div>
    </header>
  );
}
