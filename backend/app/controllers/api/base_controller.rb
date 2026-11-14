# API 共通の処理（基本設計書 4.1、6章）
# エラーはすべて { "errors": [{ "field", "code", "message" }] } の形で返す。
class Api::BaseController < ApplicationController
  # パラメーターの形式が不正なときに使う（400）
  class BadRequest < StandardError
    attr_reader :field

    def initialize(message, field: nil)
      super(message)
      @field = field
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    render_errors(:not_found, code: "not_found", message: "指定された予約が見つかりません")
  end

  rescue_from ActionController::ParameterMissing do
    render_errors(:bad_request, code: "bad_request", message: "リクエストの形式が正しくありません")
  end

  rescue_from BadRequest do |error|
    render_errors(:bad_request, code: "bad_request", message: error.message, field: error.field)
  end

  private

  # 保存して、成功ならレコードを、失敗なら 422 を返す
  def save_and_render(record, serializer:, status: :ok)
    if save_record(record)
      render json: serializer.call(record), status: status
    else
      render json: { errors: error_items(record) }, status: :unprocessable_content
    end
  end

  # 同時登録で一意制約に違反した場合も、バリデーションと同じエラーにそろえる（基本設計書 5.3）
  def save_record(record)
    record.save
  rescue ActiveRecord::RecordNotUnique
    # もう一度チェックすると、先に保存された予約が見つかり、slot_taken / day_taken のエラーになる
    if record.valid?
      # 先に保存された予約が、その後すぐ削除された場合など
      record.errors.add(:base, :conflict,
                        message: "ほかの予約と重なったため保存できませんでした。画面を更新してもう一度お試しください")
    end
    false
  end

  def error_items(record)
    record.errors.map do |error|
      {
        field: error.attribute == :base ? nil : error.attribute.to_s,
        code: error.type.to_s,
        message: error.message
      }
    end
  end

  def render_errors(status, code:, message:, field: nil)
    render json: { errors: [ { field: field, code: code, message: message } ] }, status: status
  end

  def bad_request!(message, field: nil)
    raise BadRequest.new(message, field: field)
  end
end
