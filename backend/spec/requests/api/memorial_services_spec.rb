require "rails_helper"

# 法要予約の API（基本設計書 4.4、4.5、5.3）
RSpec.describe "API 法要予約", type: :request do
  let(:valid_attributes) do
    {
      sponsor_name: "山田太郎",
      service_date: "2026-11-20",
      time_slot: 10,
      service_type: "isshuki",
      is_sodai: false,
      place: "temple",
      has_meal: true,
      officiant: "jushoku",
      note: ""
    }
  end

  def post_service(attributes)
    post "/api/memorial_services", params: { memorial_service: attributes }, as: :json
  end

  describe "GET /api/memorial_services（施主名検索）" do
    it "部分一致で検索し、日付・時間枠の新しい順に返す" do
      old = create(:memorial_service, sponsor_name: "山田太郎", service_date: Date.new(2025, 8, 10), time_slot: 14)
      newest = create(:memorial_service, sponsor_name: "山田太郎", service_date: Date.new(2027, 3, 5), time_slot: 11)
      same_day_late = create(:memorial_service, sponsor_name: "小山田花子", service_date: Date.new(2026, 11, 20),
                                                time_slot: 15)
      same_day_early = create(:memorial_service, sponsor_name: "山田一郎", service_date: Date.new(2026, 11, 20),
                                                 time_slot: 10)
      create(:memorial_service, sponsor_name: "佐藤次郎")

      get "/api/memorial_services", params: { sponsor_name: "山田" }

      expect(response).to have_http_status(:ok)
      expect(json["memorial_services"].map { |item| item["id"] })
        .to eq([ newest, same_day_late, same_day_early, old ].map(&:id))
      expect(json["truncated"]).to be(false)
    end

    it "前後の空白（全角を含む）を取り除いて検索する" do
      record = create(:memorial_service, sponsor_name: "山田太郎")

      get "/api/memorial_services", params: { sponsor_name: "　山田 " }

      expect(json["memorial_services"].map { |item| item["id"] }).to eq([ record.id ])
    end

    it "% や _ は文字としてそのまま検索する" do
      create(:memorial_service, sponsor_name: "山田太郎")
      percent = create(:memorial_service, sponsor_name: "100%山田")

      get "/api/memorial_services", params: { sponsor_name: "%" }
      expect(json["memorial_services"].map { |item| item["id"] }).to eq([ percent.id ])

      get "/api/memorial_services", params: { sponsor_name: "_" }
      expect(json["memorial_services"]).to eq([])
    end

    it "該当がなければ空の配列を返す" do
      create(:memorial_service, sponsor_name: "山田太郎")

      get "/api/memorial_services", params: { sponsor_name: "佐藤" }

      expect(response).to have_http_status(:ok)
      expect(json["memorial_services"]).to eq([])
    end

    it "200件を超える場合は新しい順に200件を返し、truncated を true にする" do
      now = Time.current
      rows = (1..201).map do |n|
        { sponsor_name: "山田#{n}", service_date: Date.new(2026, 1, 1) + n, time_slot: 10,
          service_type: "isshuki", place: "temple", officiant: "jushoku",
          created_at: now, updated_at: now }
      end
      MemorialService.insert_all!(rows)

      get "/api/memorial_services", params: { sponsor_name: "山田" }

      expect(json["memorial_services"].size).to eq(200)
      expect(json["memorial_services"].first["sponsor_name"]).to eq("山田201")
      expect(json["memorial_services"].last["sponsor_name"]).to eq("山田2")
      expect(json["truncated"]).to be(true)
    end

    [ nil, "", " 　" ].each do |keyword|
      it "施主名が #{keyword.inspect} なら 400" do
        get "/api/memorial_services", params: { sponsor_name: keyword }.compact

        expect(response).to have_http_status(:bad_request)
        expect(json["errors"]).to eq([
          { "field" => "sponsor_name", "code" => "bad_request", "message" => "施主名を入力してください" }
        ])
      end
    end
  end

  describe "GET /api/memorial_services/:id" do
    it "1件を返す" do
      record = create(:memorial_service, sponsor_name: "山田太郎")

      get "/api/memorial_services/#{record.id}"

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(record.id)
      expect(json["sponsor_name"]).to eq("山田太郎")
      expect(json.keys).not_to include("created_at", "updated_at")
    end

    it "存在しなければ 404" do
      get "/api/memorial_services/0"

      expect(response).to have_http_status(:not_found)
      expect(json["errors"]).to eq([
        { "field" => nil, "code" => "not_found", "message" => "指定された予約が見つかりません" }
      ])
    end
  end

  describe "POST /api/memorial_services" do
    it "登録して 201 と登録後の法要を返す" do
      expect { post_service(valid_attributes) }.to change(MemorialService, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include(
        "sponsor_name" => "山田太郎", "service_date" => "2026-11-20", "time_slot" => 10,
        "service_type" => "isshuki", "place" => "temple", "has_meal" => true
      )
      expect(json["id"]).to eq(MemorialService.last.id)
    end

    it "担当を指定しなくても登録できる（2人で対応）" do
      post_service(valid_attributes.merge(officiant: nil))

      expect(response).to have_http_status(:created)
      expect(json["officiant"]).to be_nil
    end

    it "総代さんの自宅での法要を登録できる" do
      post_service(valid_attributes.merge(is_sodai: true, place: "home"))

      expect(response).to have_http_status(:created)
      expect(json).to include("place" => "home", "is_sodai" => true)
      expect(json.keys).not_to include("venue")
    end

    it "入力エラーは 422 で、項目ごとのエラーを返す" do
      post_service(valid_attributes.merge(sponsor_name: "", time_slot: 16))

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to contain_exactly(
        { "field" => "sponsor_name", "code" => "blank", "message" => "施主の名前を入力してください" },
        { "field" => "time_slot", "code" => "inclusion", "message" => "時間枠を選んでください" }
      )
    end

    it "選択肢にない値は 422" do
      post_service(valid_attributes.merge(service_type: "hyakkanichi"))

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq([
        { "field" => "service_type", "code" => "inclusion", "message" => "法要の種類を選んでください" }
      ])
    end

    it "R-1 同じ枠に法要があれば 422（slot_taken）" do
      create(:memorial_service, service_date: Date.new(2026, 11, 20), time_slot: 10,
                                sponsor_name: "佐藤一郎", service_type: "sankaiki")

      expect { post_service(valid_attributes.merge(officiant: "fukujushoku")) }.not_to change(MemorialService, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq([
        { "field" => "time_slot", "code" => "slot_taken",
          "message" => "11月20日 10時枠にはすでに法要の予約があります（佐藤一郎様 三回忌）" }
      ])
    end

    it "R-2 同じ枠に葬儀の押さえがあっても登録できる" do
      create(:funeral_hold, hold_date: Date.new(2026, 11, 20), time_slot: 10)

      post_service(valid_attributes)

      expect(response).to have_http_status(:created)
    end

    it "R-6 総代でない施主の自宅での法要は 422（home_requires_sodai）" do
      post_service(valid_attributes.merge(is_sodai: false, place: "home"))

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq([
        { "field" => "place", "code" => "home_requires_sodai", "message" => "自宅での法要は総代さんのみ登録できます" }
      ])
    end

    it "許可していない項目は無視する" do
      post_service(valid_attributes.merge(id: 999_999, created_at: "2000-01-01"))

      expect(response).to have_http_status(:created)
      expect(json["id"]).not_to eq(999_999)
    end

    # memorial_service のキーを省いても、項目名が合っていれば Rails が自動で包む（ParamsWrapper）
    it "memorial_service のキーも、登録できる項目もなければ 400" do
      post "/api/memorial_services", params: { unknown: "x" }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(error_codes).to eq([ "bad_request" ])
    end

    # 基本設計書 5.3：Rails のチェックを同時にすり抜け、DBの一意制約で止まった場合
    describe "同時登録" do
      it "後から保存した側は、通常の重複と同じ 422（slot_taken）になる" do
        create(:memorial_service, service_date: Date.new(2026, 11, 20), time_slot: 10,
                                  sponsor_name: "佐藤一郎", service_type: "sankaiki")
        # 1回目のチェックでは、先の予約がまだ保存されていなかったことにする
        calls = 0
        allow_any_instance_of(MemorialService).to receive(:conflicting_service).and_wrap_original do |original, *args|
          calls += 1
          calls == 1 ? nil : original.call(*args)
        end

        expect { post_service(valid_attributes) }.not_to change(MemorialService, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to eq([
          { "field" => "time_slot", "code" => "slot_taken",
            "message" => "11月20日 10時枠にはすでに法要の予約があります（佐藤一郎様 三回忌）" }
        ])
      end

      it "先の予約がもう見つからない場合は conflict を返す" do
        allow_any_instance_of(MemorialService).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

        post_service(valid_attributes)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to eq([
          { "field" => nil, "code" => "conflict",
            "message" => "ほかの予約と重なったため保存できませんでした。画面を更新してもう一度お試しください" }
        ])
      end
    end
  end

  describe "PATCH /api/memorial_services/:id" do
    let!(:record) { create(:memorial_service, service_date: Date.new(2026, 11, 20), time_slot: 10) }

    def patch_service(attributes, id: record.id)
      patch "/api/memorial_services/#{id}", params: { memorial_service: attributes }, as: :json
    end

    it "送った項目だけを更新し、200 と更新後の法要を返す" do
      patch_service({ sponsor_name: "山田花子" })

      expect(response).to have_http_status(:ok)
      expect(json).to include("sponsor_name" => "山田花子", "service_date" => "2026-11-20", "time_slot" => 10)
      expect(record.reload.sponsor_name).to eq("山田花子")
    end

    it "同じ枠のまま更新しても、自分自身とは重複しない" do
      patch_service({ time_slot: 10, note: "人数 10名" })

      expect(response).to have_http_status(:ok)
    end

    it "チェックは更新後の値すべてに対して行う（自宅に変えるなら総代も必要）" do
      patch_service({ place: "home" })

      expect(response).to have_http_status(:unprocessable_content)
      expect(error_codes).to eq([ "home_requires_sodai" ])
      expect(record.reload.place).to eq("temple")
    end

    it "R-1 ほかの法要がある枠へは移せない" do
      create(:memorial_service, service_date: Date.new(2026, 11, 20), time_slot: 11)

      patch_service({ time_slot: 11 })

      expect(response).to have_http_status(:unprocessable_content)
      expect(error_codes).to eq([ "slot_taken" ])
      expect(record.reload.time_slot).to eq(10)
    end

    it "存在しなければ 404" do
      patch_service({ sponsor_name: "山田花子" }, id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/memorial_services/:id" do
    it "削除して 204 を返し、その枠は空きになる" do
      record = create(:memorial_service, service_date: Date.new(2026, 11, 20), time_slot: 10)

      expect { delete "/api/memorial_services/#{record.id}" }.to change(MemorialService, :count).by(-1)
      expect(response).to have_http_status(:no_content)

      post_service(valid_attributes)
      expect(response).to have_http_status(:created)
    end

    it "存在しなければ 404" do
      delete "/api/memorial_services/0"

      expect(response).to have_http_status(:not_found)
    end
  end
end
