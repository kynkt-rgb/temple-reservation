# 法要予約（基本設計書 4.4、4.5）
class Api::MemorialServicesController < Api::BaseController
  SEARCH_LIMIT = 200

  PERMITTED_ATTRIBUTES = %i[
    sponsor_name service_date time_slot service_type is_sodai
    place has_meal officiant note
  ].freeze

  # GET /api/memorial_services?sponsor_name=山田（施主名検索）
  def index
    keyword = MemorialService.strip_spaces(params[:sponsor_name].to_s)
    bad_request!("施主名を入力してください", field: "sponsor_name") if keyword.empty?

    pattern = "%#{MemorialService.sanitize_sql_like(keyword)}%"
    records = MemorialService.where("sponsor_name LIKE ?", pattern)
                             .order(service_date: :desc, time_slot: :desc)
                             .limit(SEARCH_LIMIT + 1)
                             .to_a

    render json: {
      memorial_services: records.first(SEARCH_LIMIT).map { |record| MemorialServiceSerializer.call(record) },
      truncated: records.size > SEARCH_LIMIT
    }
  end

  # GET /api/memorial_services/:id
  def show
    render json: MemorialServiceSerializer.call(find_record)
  end

  # POST /api/memorial_services
  def create
    save_and_render(MemorialService.new(record_params), serializer: MemorialServiceSerializer, status: :created)
  end

  # PATCH /api/memorial_services/:id（送った項目だけを更新する）
  def update
    record = find_record
    record.assign_attributes(record_params)
    save_and_render(record, serializer: MemorialServiceSerializer)
  end

  # DELETE /api/memorial_services/:id
  def destroy
    find_record.destroy!
    head :no_content
  end

  private

  def find_record
    MemorialService.find(params[:id])
  end

  def record_params
    params.expect(memorial_service: PERMITTED_ATTRIBUTES)
  end
end
