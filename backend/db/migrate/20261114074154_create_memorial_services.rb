# 法要予約（基本設計書 3.2）
class CreateMemorialServices < ActiveRecord::Migration[8.1]
  def change
    create_table :memorial_services do |t|
      t.string  :sponsor_name, limit: 50, null: false, comment: "施主の名前"
      t.date    :service_date, null: false, comment: "日付"
      t.integer :time_slot, limit: 1, null: false, comment: "時間枠の開始時刻（10〜15）"
      t.string  :service_type, limit: 30, null: false, comment: "法要の種類"
      t.boolean :is_sodai, null: false, default: false, comment: "施主が総代さんか"
      t.string  :place, limit: 10, null: false, default: "temple", comment: "場所（temple / home）"
      t.string  :venue, limit: 10, comment: "会場（kyakuden / kannondo）。自宅なら NULL"
      t.boolean :has_meal, null: false, default: false, comment: "食事の有無"
      t.string  :officiant, limit: 20, null: false, comment: "担当（jushoku / fukujushoku）"
      t.string  :note, limit: 500, comment: "備考"

      t.timestamps
    end

    # R-1 法要は1枠1件（結果として R-4 会場の重複も防ぐ）
    add_index :memorial_services, [ :service_date, :time_slot ], unique: true, name: "idx_ms_date_slot"
    # 施主名検索
    add_index :memorial_services, :sponsor_name, name: "idx_ms_sponsor_name"

    add_check_constraint :memorial_services, "time_slot BETWEEN 10 AND 15", name: "chk_ms_time_slot"
    add_check_constraint :memorial_services,
                         "(place = 'temple' AND venue IS NOT NULL) OR (place = 'home' AND venue IS NULL)",
                         name: "chk_ms_venue"
    # R-6 自宅は総代のみ
    add_check_constraint :memorial_services, "place = 'temple' OR is_sodai = TRUE", name: "chk_ms_home_sodai"
  end
end
