FactoryBot.define do
  factory :funeral_hold do
    sequence(:name) { |n| "鈴木家#{n}" }
    # 一意制約（1日1件）にぶつからないよう、作るたびに日付をずらす
    sequence(:hold_date) { |n| Date.new(2026, 12, 1) + n }
    time_slot { 13 }
    note { nil }
  end
end
