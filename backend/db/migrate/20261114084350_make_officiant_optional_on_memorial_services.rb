# 担当を任意にする。法要は基本2人で行うため、指定なし（NULL）は「2人で対応」を表す（2026-11-14 の仕様変更）
class MakeOfficiantOptionalOnMemorialServices < ActiveRecord::Migration[8.1]
  def change
    change_column_null :memorial_services, :officiant, true
    change_column_comment :memorial_services, :officiant,
                          from: "担当（jushoku / fukujushoku）",
                          to: "担当（jushoku / fukujushoku）。NULL は指定なし（2人で対応）"
  end
end
