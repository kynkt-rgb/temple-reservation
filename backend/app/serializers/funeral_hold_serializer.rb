# 葬儀の押さえの JSON の形（基本設計書 4.3）。created_at・updated_at は返さない
module FuneralHoldSerializer
  def self.call(record)
    {
      id: record.id,
      name: record.name,
      hold_date: record.hold_date,
      time_slot: record.time_slot,
      note: record.note
    }
  end
end
