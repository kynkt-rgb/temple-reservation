# 法要予約・葬儀の押さえに共通する、時間枠まわりの処理
module TimeSlotReservable
  extend ActiveSupport::Concern

  # 時間枠の開始時刻（基本設計書 7.1：10〜15時開始の1時間枠）
  TIME_SLOTS = (10..15).freeze

  included do
    validates :time_slot, presence: true
    validates :time_slot, inclusion: { in: TIME_SLOTS }, allow_nil: true
  end

  class_methods do
    # 前後の空白（全角スペースを含む）を取り除く
    def strip_spaces(value)
      value.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
    end
  end

  private

  # 例：「11月20日」
  def date_label(date)
    "#{date.month}月#{date.day}日"
  end

  # 例：「10時」
  def slot_label(slot)
    "#{slot}時"
  end
end
