"use client";

import Link from "next/link";
import { useEffect, useRef } from "react";
import { officiantShortLabel, placeLabel, serviceTypeLabel } from "@/constants/options";
import { formatDateJa } from "@/lib/date";
import type { FuneralHold, MemorialService } from "@/types/api";

type Props = {
  date: string;
  slot: number;
  service?: MemorialService;
  funeral?: FuneralHold;
  /** その日のどこかの枠に葬儀の押さえがあるか（R-3） */
  dayHasFuneral: boolean;
  menuOpen: boolean;
  onOpenMenu: () => void;
  onCloseMenu: () => void;
};

/** カレンダーの1セル（日付×時間枠）。法要1件と葬儀の押さえ1件が同時に入ることがある（R-2） */
export function CalendarCell({ date, slot, service, funeral, dayHasFuneral, menuOpen, onOpenMenu, onCloseMenu }: Props) {
  // 空いている部分をクリックしたときに出す選択肢（基本設計書 2.4）
  const canAddService = !service; // R-1
  const canAddFuneral = !dayHasFuneral; // R-3
  const canAdd = canAddService || canAddFuneral;
  const query = new URLSearchParams({ date, slot: String(slot) }).toString();
  const cellRef = useRef<HTMLTableCellElement>(null);

  // メニューの外をクリック、または Esc キーで閉じる
  useEffect(() => {
    if (!menuOpen) return;
    const handleClick = (event: MouseEvent) => {
      if (!cellRef.current?.contains(event.target as Node)) onCloseMenu();
    };
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") onCloseMenu();
    };
    document.addEventListener("mousedown", handleClick);
    document.addEventListener("keydown", handleKey);
    return () => {
      document.removeEventListener("mousedown", handleClick);
      document.removeEventListener("keydown", handleKey);
    };
  }, [menuOpen, onCloseMenu]);

  return (
    <td ref={cellRef} className="relative h-12 border border-gray-300 p-0 align-top">
      <div className="flex h-full min-h-12 flex-col">
        {service && (
          <Link
            href={`/services/${service.id}/edit`}
            className="block border-b border-sky-200 bg-sky-50 px-2 py-1 leading-snug hover:bg-sky-100"
          >
            <span className="block truncate font-medium">
              {service.sponsor_name}様{service.has_meal && <span title="食事あり"> 🍱</span>}
            </span>
            <span className="block truncate">{serviceTypeLabel(service.service_type)}</span>
            <span className="block truncate">
              {placeLabel(service.place)}/{officiantShortLabel(service.officiant)}
            </span>
          </Link>
        )}
        {funeral && (
          <Link
            href={`/funerals/${funeral.id}/edit`}
            className="block bg-gray-200 px-2 py-1 leading-snug hover:bg-gray-300"
          >
            <span className="block truncate font-medium">【葬儀】</span>
            <span className="block truncate">{funeral.name}</span>
          </Link>
        )}
        {canAdd && (
          <button
            type="button"
            aria-label={`${formatDateJa(date)} ${slot}時に予約を追加`}
            aria-expanded={menuOpen}
            onClick={onOpenMenu}
            className="group min-h-6 flex-1 text-center text-lg text-gray-400 hover:bg-yellow-50"
          >
            <span className={menuOpen ? "" : "invisible group-hover:visible group-focus-visible:visible"}>＋</span>
          </button>
        )}
      </div>

      {menuOpen && (
        <div role="menu" className="absolute top-full left-1/2 z-20 -translate-x-1/2 rounded border border-gray-300 bg-white py-1 text-base shadow-lg">
          {canAddService && (
            <Link role="menuitem" href={`/services/new?${query}`} className="block px-4 py-2 whitespace-nowrap hover:bg-sky-50">
              法要を登録
            </Link>
          )}
          {canAddFuneral && (
            <Link role="menuitem" href={`/funerals/new?${query}`} className="block px-4 py-2 whitespace-nowrap hover:bg-gray-100">
              葬儀を押さえる
            </Link>
          )}
        </div>
      )}
    </td>
  );
}
