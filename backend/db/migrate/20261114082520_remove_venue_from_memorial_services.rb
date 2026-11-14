# 会場（客殿／観音堂）の項目をなくす（2026-11-14 の仕様変更）
class RemoveVenueFromMemorialServices < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :memorial_services,
                            "(place = 'temple' AND venue IS NOT NULL) OR (place = 'home' AND venue IS NULL)",
                            name: "chk_ms_venue"
    remove_column :memorial_services, :venue, :string, limit: 10,
                  comment: "会場（kyakuden / kannondo）。自宅なら NULL"
  end
end
