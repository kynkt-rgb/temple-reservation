# 葬儀の押さえ（基本設計書 3.3）
class CreateFuneralHolds < ActiveRecord::Migration[8.1]
  def change
    create_table :funeral_holds do |t|
      t.string  :name, limit: 50, null: false, comment: "名前（喪家名など）"
      t.date    :hold_date, null: false, comment: "日付"
      t.integer :time_slot, limit: 1, null: false, comment: "時間枠の開始時刻（10〜15）"
      t.string  :note, limit: 500, comment: "備考"

      t.timestamps
    end

    # R-3 葬儀の押さえは1日1件
    add_index :funeral_holds, :hold_date, unique: true, name: "idx_fh_date"

    add_check_constraint :funeral_holds, "time_slot BETWEEN 10 AND 15", name: "chk_fh_time_slot"
  end
end
