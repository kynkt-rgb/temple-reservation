require "rails_helper"

# 葬儀の押さえのバリデーションと予約ルール（基本設計書 3.3、5.2）
RSpec.describe FuneralHold, type: :model do
  def error_codes(record, attribute)
    record.errors.details[attribute].map { |detail| detail[:error] }
  end

  it "ファクトリーの初期値で有効" do
    expect(build(:funeral_hold)).to be_valid
  end

  describe "名前" do
    it "空なら blank" do
      record = build(:funeral_hold, name: "")
      expect(record).not_to be_valid
      expect(error_codes(record, :name)).to include(:blank)
      expect(record.errors[:name]).to include("名前を入力してください")
    end

    it "50文字までは有効" do
      expect(build(:funeral_hold, name: "あ" * 50)).to be_valid
    end

    it "51文字なら too_long" do
      record = build(:funeral_hold, name: "あ" * 51)
      expect(record).not_to be_valid
      expect(error_codes(record, :name)).to include(:too_long)
      expect(record.errors[:name]).to include("名前は50文字以内で入力してください")
    end

    it "前後の空白（全角スペースを含む）を取り除いて保存する" do
      record = create(:funeral_hold, name: "　鈴木家 ")
      expect(record.reload.name).to eq("鈴木家")
    end
  end

  describe "日付" do
    it "空なら blank" do
      record = build(:funeral_hold, hold_date: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :hold_date)).to include(:blank)
      expect(record.errors[:hold_date]).to include("日付を入力してください")
    end
  end

  describe "時間枠" do
    it "空なら blank" do
      record = build(:funeral_hold, time_slot: nil)
      expect(record).not_to be_valid
      expect(error_codes(record, :time_slot)).to eq([ :blank ])
      expect(record.errors[:time_slot]).to include("時間枠を選んでください")
    end

    [ 10, 15 ].each do |slot|
      it "#{slot}時は有効" do
        expect(build(:funeral_hold, time_slot: slot)).to be_valid
      end
    end

    [ 9, 16 ].each do |slot|
      it "#{slot}時なら inclusion" do
        record = build(:funeral_hold, time_slot: slot)
        expect(record).not_to be_valid
        expect(error_codes(record, :time_slot)).to include(:inclusion)
      end
    end
  end

  describe "備考" do
    it "501文字なら too_long" do
      record = build(:funeral_hold, note: "あ" * 501)
      expect(record).not_to be_valid
      expect(error_codes(record, :note)).to include(:too_long)
      expect(record.errors[:note]).to include("備考は500文字以内で入力してください")
    end
  end

  describe "R-3 葬儀の押さえは1日1件" do
    let(:date) { Date.new(2026, 11, 20) }
    let!(:existing) { create(:funeral_hold, hold_date: date, time_slot: 13) }

    it "同じ日には、時間枠が違っても登録できず、既存の枠が分かるメッセージを返す" do
      record = build(:funeral_hold, hold_date: date, time_slot: 10)
      expect(record).not_to be_valid
      expect(error_codes(record, :hold_date)).to include(:day_taken)
      expect(record.errors[:hold_date]).to include("11月20日にはすでに葬儀の押さえがあります（13時枠）")
    end

    it "別の日には登録できる" do
      expect(build(:funeral_hold, hold_date: date + 1, time_slot: 13)).to be_valid
    end

    it "編集するとき、自分自身とは重複しない（同じ日の別の枠へ移せる）" do
      existing.time_slot = 14
      expect(existing).to be_valid
    end

    it "編集で、ほかの葬儀の押さえがある日へは移せない" do
      other = create(:funeral_hold, hold_date: date + 1)
      other.hold_date = date
      expect(other).not_to be_valid
      expect(error_codes(other, :hold_date)).to include(:day_taken)
    end
  end

  describe "R-2 法要がある枠でも葬儀の押さえは登録できる" do
    it "同じ日付・時間枠に法要があっても登録できる" do
      date = Date.new(2026, 11, 20)
      create(:memorial_service, service_date: date, time_slot: 13)
      expect(build(:funeral_hold, hold_date: date, time_slot: 13)).to be_valid
    end
  end

  describe "DBの制約" do
    def save_without_validation(**attributes)
      build(:funeral_hold, **attributes).save!(validate: false)
    end

    it "同じ日の2件目は一意制約で保存できない（R-3）" do
      date = Date.new(2026, 11, 20)
      create(:funeral_hold, hold_date: date, time_slot: 13)
      expect { save_without_validation(hold_date: date, time_slot: 10) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "時間枠が範囲外なら保存できない" do
      expect { save_without_validation(time_slot: 9) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
