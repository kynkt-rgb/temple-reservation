require "rails_helper"

# 葬儀の押さえの API（基本設計書 4.6、5.3）
RSpec.describe "API 葬儀の押さえ", type: :request do
  let(:valid_attributes) { { name: "鈴木家", hold_date: "2026-11-20", time_slot: 13, note: "" } }

  def post_hold(attributes)
    post "/api/funeral_holds", params: { funeral_hold: attributes }, as: :json
  end

  describe "GET /api/funeral_holds/:id" do
    it "1件を返す" do
      record = create(:funeral_hold, name: "鈴木家", hold_date: Date.new(2026, 11, 20), time_slot: 13)

      get "/api/funeral_holds/#{record.id}"

      expect(response).to have_http_status(:ok)
      expect(json).to eq("id" => record.id, "name" => "鈴木家", "hold_date" => "2026-11-20",
                         "time_slot" => 13, "note" => nil)
    end

    it "存在しなければ 404" do
      get "/api/funeral_holds/0"

      expect(response).to have_http_status(:not_found)
      expect(error_codes).to eq([ "not_found" ])
    end
  end

  describe "POST /api/funeral_holds" do
    it "登録して 201 と登録後の葬儀の押さえを返す" do
      expect { post_hold(valid_attributes) }.to change(FuneralHold, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "鈴木家", "hold_date" => "2026-11-20", "time_slot" => 13)
    end

    it "入力エラーは 422" do
      post_hold(valid_attributes.merge(name: ""))

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq([
        { "field" => "name", "code" => "blank", "message" => "名前を入力してください" }
      ])
    end

    it "R-3 同じ日に葬儀の押さえがあれば、時間枠が違っても 422（day_taken）" do
      create(:funeral_hold, hold_date: Date.new(2026, 11, 20), time_slot: 13)

      expect { post_hold(valid_attributes.merge(time_slot: 10)) }.not_to change(FuneralHold, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to eq([
        { "field" => "hold_date", "code" => "day_taken",
          "message" => "11月20日にはすでに葬儀の押さえがあります（13時枠）" }
      ])
    end

    it "R-2 同じ枠に法要があっても登録できる" do
      create(:memorial_service, service_date: Date.new(2026, 11, 20), time_slot: 13)

      post_hold(valid_attributes)

      expect(response).to have_http_status(:created)
    end

    # funeral_hold のキーを省いても、項目名が合っていれば Rails が自動で包む（ParamsWrapper）
    it "funeral_hold のキーも、登録できる項目もなければ 400" do
      post "/api/funeral_holds", params: { unknown: "x" }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(error_codes).to eq([ "bad_request" ])
    end

    describe "同時登録（基本設計書 5.3）" do
      it "後から保存した側は、通常の重複と同じ 422（day_taken）になる" do
        create(:funeral_hold, hold_date: Date.new(2026, 11, 20), time_slot: 11)
        calls = 0
        allow_any_instance_of(FuneralHold).to receive(:conflicting_hold).and_wrap_original do |original, *args|
          calls += 1
          calls == 1 ? nil : original.call(*args)
        end

        expect { post_hold(valid_attributes) }.not_to change(FuneralHold, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to eq([
          { "field" => "hold_date", "code" => "day_taken",
            "message" => "11月20日にはすでに葬儀の押さえがあります（11時枠）" }
        ])
      end
    end
  end

  describe "PATCH /api/funeral_holds/:id" do
    let!(:record) { create(:funeral_hold, hold_date: Date.new(2026, 11, 20), time_slot: 13) }

    def patch_hold(attributes, id: record.id)
      patch "/api/funeral_holds/#{id}", params: { funeral_hold: attributes }, as: :json
    end

    it "送った項目だけを更新する（同じ日の別の枠へ移せる）" do
      patch_hold({ time_slot: 14 })

      expect(response).to have_http_status(:ok)
      expect(json).to include("time_slot" => 14, "hold_date" => "2026-11-20", "name" => record.name)
    end

    it "R-3 ほかの葬儀の押さえがある日へは移せない" do
      create(:funeral_hold, hold_date: Date.new(2026, 11, 21))

      patch_hold({ hold_date: "2026-11-21" })

      expect(response).to have_http_status(:unprocessable_content)
      expect(error_codes).to eq([ "day_taken" ])
      expect(record.reload.hold_date).to eq(Date.new(2026, 11, 20))
    end

    it "存在しなければ 404" do
      patch_hold({ name: "田中家" }, id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/funeral_holds/:id" do
    it "削除して 204 を返す" do
      record = create(:funeral_hold)

      expect { delete "/api/funeral_holds/#{record.id}" }.to change(FuneralHold, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "存在しなければ 404" do
      delete "/api/funeral_holds/0"

      expect(response).to have_http_status(:not_found)
    end
  end
end
