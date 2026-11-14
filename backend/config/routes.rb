Rails.application.routes.draw do
  # ヘルスチェック。アプリが起動していれば 200 を返す
  get "up" => "rails/health#show", as: :rails_health_check

  # API（基本設計書 4.2）
  namespace :api, defaults: { format: :json } do
    get "calendar", to: "calendars#show"
    resources :memorial_services, only: %i[index show create update destroy]
    resources :funeral_holds, only: %i[show create update destroy]
  end
end
