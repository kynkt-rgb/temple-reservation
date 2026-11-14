# リクエストスペック用のヘルパー
module JsonHelpers
  def json
    response.parsed_body
  end

  # エラーレスポンスの code の一覧
  def error_codes
    json["errors"].map { |error| error["code"] }
  end
end

RSpec.configure do |config|
  config.include JsonHelpers, type: :request
end
