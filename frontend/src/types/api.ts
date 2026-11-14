// API のリクエスト・レスポンスの型（基本設計書 4章）

export type ServiceType =
  | "shijukunichi"
  | "isshuki"
  | "sankaiki"
  | "nanakaiki"
  | "jusankaiki"
  | "jushichikaiki"
  | "nijusankaiki"
  | "nijushichikaiki"
  | "sanjusankaiki"
  | "gojukkaiki"
  | "other";

export type Place = "temple" | "home";
export type Officiant = "jushoku" | "fukujushoku";

/** 法要予約 */
export type MemorialService = {
  id: number;
  sponsor_name: string;
  /** YYYY-MM-DD */
  service_date: string;
  time_slot: number;
  service_type: ServiceType;
  is_sodai: boolean;
  place: Place;
  has_meal: boolean;
  /** null は指定なし（2人で対応） */
  officiant: Officiant | null;
  note: string | null;
};

/** 葬儀の押さえ */
export type FuneralHold = {
  id: number;
  name: string;
  /** YYYY-MM-DD */
  hold_date: string;
  time_slot: number;
  note: string | null;
};

/** 法要予約の登録・更新で送る値（フォームの途中では未選択の項目がある） */
export type MemorialServiceInput = {
  sponsor_name: string;
  service_date: string;
  time_slot: number | null;
  service_type: ServiceType | null;
  is_sodai: boolean;
  place: Place;
  has_meal: boolean;
  officiant: Officiant | null;
  note: string;
};

/** 葬儀の押さえの登録・更新で送る値 */
export type FuneralHoldInput = {
  name: string;
  hold_date: string;
  time_slot: number | null;
  note: string;
};

/** GET /api/calendar */
export type CalendarResponse = {
  month: string;
  memorial_services: MemorialService[];
  funeral_holds: FuneralHold[];
};

/** GET /api/memorial_services */
export type SearchResponse = {
  memorial_services: MemorialService[];
  truncated: boolean;
};

/** エラーレスポンスの1件（基本設計書 4.1） */
export type ApiErrorItem = {
  field: string | null;
  code: string;
  message: string;
};

export type ApiErrorResponse = {
  errors: ApiErrorItem[];
};
