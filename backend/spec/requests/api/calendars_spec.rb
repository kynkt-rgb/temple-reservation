require "rails_helper"

# GET /api/calendar（基本設計書 4.3）
RSpec.describe "API 月カレンダー", type: :request do
  describe "GET /api/calendar" do
    it "指定月の法要と葬儀の押さえを、日付・時間枠の昇順で返す" do
      late = create(:memorial_service, service_date: Date.new(2026, 11, 20), time_slot: 14)
      early = create(:memorial_service, service_date: Date.new(2026, 11, 20), time_slot: 10)
      first_day = create(:memorial_service, service_date: Date.new(2026, 11, 1), time_slot: 15)
      last_day = create(:memorial_service, service_date: Date.new(2026, 11, 30), time_slot: 10)
      create(:memorial_service, service_date: Date.new(2026, 10, 31))
      create(:memorial_service, service_date: Date.new(2026, 12, 1))

      funeral_late = create(:funeral_hold, hold_date: Date.new(2026, 11, 25))
      funeral_early = create(:funeral_hold, hold_date: Date.new(2026, 11, 2))
      create(:funeral_hold, hold_date: Date.new(2026, 12, 2))

      get "/api/calendar", params: { month: "2026-11" }

      expect(response).to have_http_status(:ok)
      expect(json["month"]).to eq("2026-11")
      expect(json["memorial_services"].map { |item| item["id"] })
        .to eq([ first_day, early, late, last_day ].map(&:id))
      expect(json["funeral_holds"].map { |item| item["id"] }).to eq([ funeral_early, funeral_late ].map(&:id))
    end

    it "法要・葬儀の押さえを設計書どおりの形で返す" do
      service = create(:memorial_service, sponsor_name: "山田太郎", service_date: Date.new(2026, 11, 20),
                                          time_slot: 10, service_type: "isshuki",
                                          has_meal: true, note: "参列 8名")
      hold = create(:funeral_hold, name: "鈴木家", hold_date: Date.new(2026, 11, 2), time_slot: 13)

      get "/api/calendar", params: { month: "2026-11" }

      expect(json["memorial_services"].first).to eq(
        "id" => service.id, "sponsor_name" => "山田太郎", "service_date" => "2026-11-20",
        "time_slot" => 10, "service_type" => "isshuki", "is_sodai" => false, "place" => "temple",
        "has_meal" => true, "officiant" => "jushoku", "note" => "参列 8名"
      )
      expect(json["funeral_holds"].first).to eq(
        "id" => hold.id, "name" => "鈴木家", "hold_date" => "2026-11-02", "time_slot" => 13, "note" => nil
      )
    end

    it "予約がない月は空の配列を返す" do
      get "/api/calendar", params: { month: "2027-01" }

      expect(response).to have_http_status(:ok)
      expect(json["memorial_services"]).to eq([])
      expect(json["funeral_holds"]).to eq([])
    end

    [ nil, "", "2026-13", "2026-00", "2026-1", "202611", "abc" ].each do |month|
      it "month が #{month.inspect} なら 400" do
        get "/api/calendar", params: { month: month }.compact

        expect(response).to have_http_status(:bad_request)
        expect(json["errors"]).to eq([
          { "field" => "month", "code" => "bad_request",
            "message" => "年月は YYYY-MM の形式で指定してください（例：2026-11）" }
        ])
      end
    end
  end
end
