# 葬儀の押さえ（基本設計書 4.6）
class Api::FuneralHoldsController < Api::BaseController
  PERMITTED_ATTRIBUTES = %i[name hold_date time_slot note].freeze

  # GET /api/funeral_holds/:id
  def show
    render json: FuneralHoldSerializer.call(find_record)
  end

  # POST /api/funeral_holds
  def create
    save_and_render(FuneralHold.new(record_params), serializer: FuneralHoldSerializer, status: :created)
  end

  # PATCH /api/funeral_holds/:id（送った項目だけを更新する）
  def update
    record = find_record
    record.assign_attributes(record_params)
    save_and_render(record, serializer: FuneralHoldSerializer)
  end

  # DELETE /api/funeral_holds/:id
  def destroy
    find_record.destroy!
    head :no_content
  end

  private

  def find_record
    FuneralHold.find(params[:id])
  end

  def record_params
    params.expect(funeral_hold: PERMITTED_ATTRIBUTES)
  end
end
