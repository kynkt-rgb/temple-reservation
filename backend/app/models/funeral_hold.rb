# 葬儀の押さえ（基本設計書 3.3、5.2）
# 担当は持たない。法要とは別テーブルなので、同じ枠に法要が1件あっても登録できる（R-2、R-5）。
class FuneralHold < ApplicationRecord
  include TimeSlotReservable

  normalizes :name, with: ->(name) { strip_spaces(name) }

  validates :name, presence: true, length: { maximum: 50 }
  validates :hold_date, presence: true
  validates :note, length: { maximum: 500 }

  validate :day_must_be_free # R-3

  # 同じ日にある、自分以外の葬儀の押さえ
  def conflicting_hold
    return if hold_date.blank?

    self.class.where(hold_date: hold_date).where.not(id: id).first
  end

  # R-3 違反のメッセージ。DBの一意制約違反（同時登録）のときにも使う（基本設計書 5.3）
  def day_taken_message(existing = conflicting_hold)
    I18n.t(
      "errors.funeral_hold.day_taken",
      date: date_label(hold_date),
      slot: slot_label(existing.time_slot)
    )
  end

  private

  def day_must_be_free
    existing = conflicting_hold
    errors.add(:hold_date, :day_taken, message: day_taken_message(existing)) if existing
  end
end
