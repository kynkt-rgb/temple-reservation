# 法要予約（基本設計書 3.2、5.2）
class MemorialService < ApplicationRecord
  include TimeSlotReservable

  SERVICE_TYPES = %w[
    shijukunichi isshuki sankaiki nanakaiki jusankaiki jushichikaiki
    nijusankaiki nijushichikaiki sanjusankaiki gojukkaiki other
  ].freeze

  # DBには英語の文字列で保存する（基本設計書 3.4）
  enum :service_type, SERVICE_TYPES.index_with(&:itself), prefix: true, validate: { allow_nil: true }
  enum :place, { temple: "temple", home: "home" }, prefix: true, validate: { allow_nil: true }
  enum :officiant, { jushoku: "jushoku", fukujushoku: "fukujushoku" }, prefix: true, validate: { allow_nil: true }

  normalizes :sponsor_name, with: ->(name) { strip_spaces(name) }

  validates :sponsor_name, presence: true, length: { maximum: 50 }
  validates :service_date, presence: true
  validates :service_type, presence: true
  validates :place, presence: true
  validates :officiant, presence: true
  validates :is_sodai, inclusion: { in: [ true, false ] }
  validates :has_meal, inclusion: { in: [ true, false ] }
  validates :note, length: { maximum: 500 }

  validate :home_requires_sodai   # R-6
  validate :slot_must_be_free     # R-1

  # 同じ日付・時間枠にある、自分以外の法要
  def conflicting_service
    return if service_date.blank? || time_slot.blank?

    self.class.where(service_date: service_date, time_slot: time_slot).where.not(id: id).first
  end

  # R-1 違反のメッセージ。DBの一意制約違反（同時登録）のときにも使う（基本設計書 5.3）
  def slot_taken_message(existing = conflicting_service)
    I18n.t(
      "errors.memorial_service.slot_taken",
      date: date_label(service_date),
      slot: slot_label(time_slot),
      sponsor_name: existing.sponsor_name,
      service_type: existing.service_type_label
    )
  end

  # 例：「一周忌」
  def service_type_label
    I18n.t("enums.memorial_service.service_type.#{service_type}")
  end

  private

  def home_requires_sodai
    errors.add(:place, :home_requires_sodai) if place_home? && !is_sodai
  end

  def slot_must_be_free
    existing = conflicting_service
    errors.add(:time_slot, :slot_taken, message: slot_taken_message(existing)) if existing
  end
end
