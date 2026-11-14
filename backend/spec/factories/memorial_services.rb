FactoryBot.define do
  factory :memorial_service do
    sequence(:sponsor_name) { |n| "山田太郎#{n}" }
    # 一意制約（日付・時間枠）にぶつからないよう、作るたびに日付をずらす
    sequence(:service_date) { |n| Date.new(2026, 12, 1) + n }
    time_slot { 10 }
    service_type { "isshuki" }
    is_sodai { false }
    place { "temple" }
    venue { "kyakuden" }
    has_meal { false }
    officiant { "jushoku" }
    note { nil }

    # 総代さんの自宅での法要
    trait :at_home do
      is_sodai { true }
      place { "home" }
      venue { nil }
    end
  end
end
