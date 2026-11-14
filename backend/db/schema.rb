# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_14_082520) do
  create_table "funeral_holds", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", limit: 50, null: false, comment: "名前（喪家名など）"
    t.date "hold_date", null: false, comment: "日付"
    t.integer "time_slot", limit: 1, null: false, comment: "時間枠の開始時刻（10〜15）"
    t.string "note", limit: 500, comment: "備考"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hold_date"], name: "idx_fh_date", unique: true
    t.check_constraint "`time_slot` between 10 and 15", name: "chk_fh_time_slot"
  end

  create_table "memorial_services", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "sponsor_name", limit: 50, null: false, comment: "施主の名前"
    t.date "service_date", null: false, comment: "日付"
    t.integer "time_slot", limit: 1, null: false, comment: "時間枠の開始時刻（10〜15）"
    t.string "service_type", limit: 30, null: false, comment: "法要の種類"
    t.boolean "is_sodai", default: false, null: false, comment: "施主が総代さんか"
    t.string "place", limit: 10, default: "temple", null: false, comment: "場所（temple / home）"
    t.boolean "has_meal", default: false, null: false, comment: "食事の有無"
    t.string "officiant", limit: 20, null: false, comment: "担当（jushoku / fukujushoku）"
    t.string "note", limit: 500, comment: "備考"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_date", "time_slot"], name: "idx_ms_date_slot", unique: true
    t.index ["sponsor_name"], name: "idx_ms_sponsor_name"
    t.check_constraint "(`place` = _utf8mb4'temple') or (`is_sodai` = true)", name: "chk_ms_home_sodai"
    t.check_constraint "`time_slot` between 10 and 15", name: "chk_ms_time_slot"
  end
end
