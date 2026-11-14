// API を呼び出す関数とエラーの変換（基本設計書 4章、7章）
import type {
  ApiErrorItem,
  ApiErrorResponse,
  CalendarResponse,
  FuneralHold,
  FuneralHoldInput,
  MemorialService,
  MemorialServiceInput,
  SearchResponse,
} from "@/types/api";

export const NETWORK_ERROR_MESSAGE = "通信に失敗しました。もう一度お試しください";

/** API がエラーを返したとき、または通信に失敗したときに投げる */
export class ApiError extends Error {
  /** HTTP ステータス。通信に失敗したときは 0 */
  readonly status: number;
  readonly errors: ApiErrorItem[];

  constructor(status: number, errors: ApiErrorItem[]) {
    super(errors.map((error) => error.message).join("\n"));
    this.name = "ApiError";
    this.status = status;
    this.errors = errors;
  }
}

function networkError(): ApiError {
  return new ApiError(0, [{ field: null, code: "network_error", message: NETWORK_ERROR_MESSAGE }]);
}

function isErrorResponse(body: unknown): body is ApiErrorResponse {
  return typeof body === "object" && body !== null && Array.isArray((body as ApiErrorResponse).errors);
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  let response: Response;
  try {
    response = await fetch(`/api${path}`, {
      ...init,
      headers: { Accept: "application/json", "Content-Type": "application/json", ...init.headers },
      cache: "no-store",
    });
  } catch {
    throw networkError();
  }

  if (response.status === 204) return undefined as T;

  const body: unknown = await response.json().catch(() => null);
  if (!response.ok) {
    throw isErrorResponse(body) ? new ApiError(response.status, body.errors) : networkError();
  }
  return body as T;
}

// --- 月カレンダー ---

export const getCalendar = (month: string) =>
  request<CalendarResponse>(`/calendar?month=${encodeURIComponent(month)}`);

// --- 法要予約 ---

export const searchMemorialServices = (sponsorName: string) =>
  request<SearchResponse>(`/memorial_services?sponsor_name=${encodeURIComponent(sponsorName)}`);

export const getMemorialService = (id: string) => request<MemorialService>(`/memorial_services/${id}`);

export const createMemorialService = (input: MemorialServiceInput) =>
  request<MemorialService>("/memorial_services", {
    method: "POST",
    body: JSON.stringify({ memorial_service: input }),
  });

export const updateMemorialService = (id: number, input: MemorialServiceInput) =>
  request<MemorialService>(`/memorial_services/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ memorial_service: input }),
  });

export const deleteMemorialService = (id: number) =>
  request<void>(`/memorial_services/${id}`, { method: "DELETE" });

// --- 葬儀の押さえ ---

export const getFuneralHold = (id: string) => request<FuneralHold>(`/funeral_holds/${id}`);

export const createFuneralHold = (input: FuneralHoldInput) =>
  request<FuneralHold>("/funeral_holds", {
    method: "POST",
    body: JSON.stringify({ funeral_hold: input }),
  });

export const updateFuneralHold = (id: number, input: FuneralHoldInput) =>
  request<FuneralHold>(`/funeral_holds/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ funeral_hold: input }),
  });

export const deleteFuneralHold = (id: number) => request<void>(`/funeral_holds/${id}`, { method: "DELETE" });

// --- エラーの変換 ---

export function toApiError(error: unknown): ApiError {
  return error instanceof ApiError ? error : networkError();
}
