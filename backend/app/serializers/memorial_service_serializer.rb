# 法要予約の JSON の形（基本設計書 4.3）。created_at・updated_at は返さない
module MemorialServiceSerializer
  def self.call(record)
    {
      id: record.id,
      sponsor_name: record.sponsor_name,
      service_date: record.service_date,
      time_slot: record.time_slot,
      service_type: record.service_type,
      is_sodai: record.is_sodai,
      place: record.place,
      has_meal: record.has_meal,
      officiant: record.officiant,
      note: record.note
    }
  end
end
