# GET /api/calendar?month=2026-11（基本設計書 4.3）
class Api::CalendarsController < Api::BaseController
  MONTH_FORMAT = /\A(\d{4})-(0[1-9]|1[0-2])\z/

  def show
    first_day = parse_month(params[:month])
    days = first_day..first_day.end_of_month

    render json: {
      month: params[:month],
      memorial_services: MemorialService.where(service_date: days).order(:service_date, :time_slot)
                                        .map { |record| MemorialServiceSerializer.call(record) },
      funeral_holds: FuneralHold.where(hold_date: days).order(:hold_date, :time_slot)
                                .map { |record| FuneralHoldSerializer.call(record) }
    }
  end

  private

  def parse_month(value)
    match = MONTH_FORMAT.match(value.to_s)
    bad_request!("年月は YYYY-MM の形式で指定してください（例：2026-11）", field: "month") unless match

    Date.new(match[1].to_i, match[2].to_i, 1)
  end
end
