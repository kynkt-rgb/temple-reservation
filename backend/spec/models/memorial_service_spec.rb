require "rails_helper"

# 法要予約のバリデーションと予約ルール（基本設計書 3.2、5.2）
RSpec.describe MemorialService, type: :model do
  # 指定した項目のエラーコード（:blank、:slot_taken など）
  def error_codes(record, attribute)
    record.errors.details[attribute].map { |detail| detail[:error] }
  end

  it "ファクトリーの初期値で有効" do
    expect(build(:memorial_service)).to be_valid
  end

  it "総代さんの自宅での法要は有効" do
    expect(build(:memorial_service, :at_home)).to be_valid
  end

  describe "施主の名前" do
    it "空なら blank" do
      record = build(:memorial_service, sponsor_name: "")
      expect(record).not_to be_valid
      expect(error_codes(record, :sponsor_name)).to include(:blank)
      expect(record.errors[:sponsor_name]).to include("施主の名前を入力してください")
    end

    it "空白だけなら blank" do
      record = build(:memorial_service, sponsor_name: " 　 ")
      expect(record).not_to be_valid
      expect(error_codes(record, :sponsor_name)).to include(:blank)
    end

    it "50文字までは有効" do
      expect(build(:memorial_service, sponsor_name: "あ" * 50)).to be_valid
    end

    it "51文字なら too_long" do
      record = build(:memorial_service, sponsor_name: "あ" * 51)
      expect(record).not_to be_valid
      expect(error_codes(record, :sponsor_name)).to include(:too_long)
      expect(record.errors[:sponsor_name]).to include("施主の名前は50文字以内で入力してください")
    end

    it "前後の空白（全角スペースを含む）を取り除いて保存する" do
      record = create(:memorial_service, sponsor_name: "　山田 太郎 ")
      expect(record.reload.sponsor_name).to eq("山田 太郎")
    end
  end

  describe "日付" do
    it "空なら blank" do
      record = build(:memorial_service, service_date: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :service_date)).to include(:blank)
      expect(record.errors[:service_date]).to include("日付を入力してください")
    end

    it "日付として正しくない値なら blank" do
      record = build(:memorial_service, service_date: "2026-02-30")
      expect(record).not_to be_valid
      expect(error_codes(record, :service_date)).to include(:blank)
    end
  end

  describe "時間枠" do
    it "空なら blank" do
      record = build(:memorial_service, time_slot: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :time_slot)).to eq([ :blank ])
      expect(record.errors[:time_slot]).to include("時間枠を選んでください")
    end

    [ 10, 15 ].each do |slot|
      it "#{slot}時は有効" do
        expect(build(:memorial_service, time_slot: slot)).to be_valid
      end
    end

    [ 9, 16 ].each do |slot|
      it "#{slot}時なら inclusion" do
        record = build(:memorial_service, time_slot: slot)
        expect(record).not_to be_valid
        expect(error_codes(record, :time_slot)).to include(:inclusion)
      end
    end
  end

  describe "法要の種類" do
    it "空なら blank" do
      record = build(:memorial_service, service_type: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :service_type)).to eq([ :blank ])
      expect(record.errors[:service_type]).to include("法要の種類を選んでください")
    end

    it "選択肢にない値なら inclusion" do
      record = build(:memorial_service, service_type: "hyakkanichi")
      expect(record).not_to be_valid
      expect(error_codes(record, :service_type)).to include(:inclusion)
    end

    it "選択肢の値はすべて有効" do
      MemorialService::SERVICE_TYPES.each do |type|
        expect(build(:memorial_service, service_type: type)).to be_valid
      end
    end
  end

  describe "担当" do
    it "空なら blank" do
      record = build(:memorial_service, officiant: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :officiant)).to eq([ :blank ])
      expect(record.errors[:officiant]).to include("担当を選んでください")
    end

    it "選択肢にない値なら inclusion" do
      record = build(:memorial_service, officiant: "kanshu")
      expect(record).not_to be_valid
      expect(error_codes(record, :officiant)).to include(:inclusion)
    end
  end

  describe "場所" do
    it "空なら blank" do
      record = build(:memorial_service, place: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :place)).to eq([ :blank ])
      expect(record.errors[:place]).to include("場所を選んでください")
    end

    it "選択肢にない値なら inclusion" do
      record = build(:memorial_service, place: "hall")
      expect(record).not_to be_valid
      expect(error_codes(record, :place)).to include(:inclusion)
    end
  end

  describe "総代・食事" do
    it "総代が nil なら inclusion" do
      record = build(:memorial_service, is_sodai: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :is_sodai)).to include(:inclusion)
    end

    it "食事が nil なら inclusion" do
      record = build(:memorial_service, has_meal: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :has_meal)).to include(:inclusion)
    end
  end

  describe "備考" do
    it "500文字までは有効" do
      expect(build(:memorial_service, note: "あ" * 500)).to be_valid
    end

    it "501文字なら too_long" do
      record = build(:memorial_service, note: "あ" * 501)
      expect(record).not_to be_valid
      expect(error_codes(record, :note)).to include(:too_long)
      expect(record.errors[:note]).to include("備考は500文字以内で入力してください")
    end
  end

  describe "初期値" do
    it "場所はお寺、総代・食事は「いいえ」" do
      record = described_class.new
      expect(record.place).to eq("temple")
      expect(record.is_sodai).to be(false)
      expect(record.has_meal).to be(false)
    end
  end

  describe "R-1 法要は1枠1件" do
    let(:date) { Date.new(2026, 11, 20) }
    let!(:existing) do
      create(:memorial_service, service_date: date, time_slot: 10, sponsor_name: "山田太郎", service_type: "isshuki")
    end

    it "同じ日付・時間枠には登録できず、既存の予約が分かるメッセージを返す" do
      record = build(:memorial_service, service_date: date, time_slot: 10)
      expect(record).not_to be_valid
      expect(error_codes(record, :time_slot)).to include(:slot_taken)
      expect(record.errors[:time_slot]).to include("11月20日 10時枠にはすでに法要の予約があります（山田太郎様 一周忌）")
    end

    it "場所が自宅でも、同じ枠には登録できない" do
      record = build(:memorial_service, :at_home, service_date: date, time_slot: 10)
      expect(record).not_to be_valid
      expect(error_codes(record, :time_slot)).to include(:slot_taken)
    end

    it "同じ日の別の時間枠には登録できる" do
      expect(build(:memorial_service, service_date: date, time_slot: 11)).to be_valid
    end

    it "別の日の同じ時間枠には登録できる" do
      expect(build(:memorial_service, service_date: date + 1, time_slot: 10)).to be_valid
    end

    it "編集するとき、自分自身とは重複しない" do
      existing.sponsor_name = "山田花子"
      expect(existing).to be_valid
    end

    it "編集で、ほかの法要がある枠へは移せない" do
      other = create(:memorial_service, service_date: date, time_slot: 11)
      other.time_slot = 10
      expect(other).not_to be_valid
      expect(error_codes(other, :time_slot)).to include(:slot_taken)
    end
  end

  describe "R-2 葬儀の押さえがある枠でも法要は1件受けられる" do
    it "同じ日付・時間枠に葬儀の押さえがあっても登録できる" do
      date = Date.new(2026, 11, 20)
      create(:funeral_hold, hold_date: date, time_slot: 10)
      expect(build(:memorial_service, service_date: date, time_slot: 10)).to be_valid
    end
  end

  describe "R-6 自宅での法要は総代のみ" do
    it "総代でない施主は自宅を選べない" do
      record = build(:memorial_service, :at_home, is_sodai: false)
      expect(record).not_to be_valid
      expect(error_codes(record, :place)).to include(:home_requires_sodai)
      expect(record.errors[:place]).to include("自宅での法要は総代さんのみ登録できます")
    end

    it "総代さんはお寺でも登録できる" do
      expect(build(:memorial_service, is_sodai: true)).to be_valid
    end
  end

  # バリデーションをすり抜けた場合（同時登録など）でも、DBの制約で防ぐ（基本設計書 5.3）
  describe "DBの制約" do
    def save_without_validation(**attributes)
      build(:memorial_service, **attributes).save!(validate: false)
    end

    it "同じ日付・時間枠の2件目は一意制約で保存できない（R-1）" do
      date = Date.new(2026, 11, 20)
      create(:memorial_service, service_date: date, time_slot: 10)
      expect { save_without_validation(service_date: date, time_slot: 10) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "時間枠が範囲外なら保存できない" do
      expect { save_without_validation(time_slot: 16) }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "総代でない自宅の法要は保存できない（R-6）" do
      expect { save_without_validation(is_sodai: false, place: "home") }
        .to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "#slot_taken_message" do
    it "一意制約違反のときにも、既存の予約からメッセージを作れる" do
      date = Date.new(2026, 11, 20)
      create(:memorial_service, service_date: date, time_slot: 14, sponsor_name: "佐藤一郎", service_type: "sankaiki")
      record = build(:memorial_service, service_date: date, time_slot: 14)
      expect(record.slot_taken_message).to eq("11月20日 14時枠にはすでに法要の予約があります（佐藤一郎様 三回忌）")
    end
  end
end
