Rails.application.routes.draw do
  root "pages#landing"

  devise_for :users, path: "cuenta", path_names: {
    sign_in: "ingresar",
    sign_out: "salir",
    sign_up: "registro"
  }

  devise_scope :user do
    get "cuenta/salir", to: "devise/sessions#destroy"
  end

  # Onboarding Routes
  get  "onboarding/paso_1",    to: "onboarding#paso_1",    as: :onboarding_paso_1
  post "onboarding/paso_2",    to: "onboarding#paso_2",    as: :onboarding_paso_2
  get  "onboarding/paso_2",    to: "onboarding#paso_2"
  post "onboarding/paso_3",    to: "onboarding#paso_3",    as: :onboarding_paso_3
  get  "onboarding/paso_3",    to: "onboarding#paso_3"
  post "onboarding/completar", to: "onboarding#completar", as: :onboarding_completar

  resources :trades do
    collection do
      get  :import
      post :import_csv
    end
  end

  resources :strategies

  resource :analytics, only: [:show]

  # Pro Tools Hub (Backtesting + Prop Firms)
  get  "pro-tools",           to: "pro_tools#index",    as: :pro_tools
  resources :backtest_sessions, path: "pro-tools/sesiones", only: [:create, :show, :destroy]
  resources :prop_transactions,  path: "pro-tools/prop-firms", only: [:index, :create, :destroy], as: :prop_ledger
  resources :prop_firm_accounts
  # Legacy aliases (keep working links)
  get  "prop_firms",          to: redirect("/pro-tools"), as: :prop_transactions
  get  "backtester",          to: redirect("/pro-tools"), as: :backtester

  resource :ai_coach, controller: "ai_coach", only: [:show] do
    post :analyze_trade
    post :chat
    delete :reset
  end

  get "dashboard", to: "dashboard#index", as: :dashboard
  get "calendar", to: "calendar#show", as: :calendar
  get "up" => "rails/health#show", as: :rails_health_check
  get "perfil", to: "users/profile#show", as: :profile
  patch "perfil", to: "users/profile#update"
  put "perfil", to: "users/profile#update"
  
  resources :notifications, only: [:index] do
    collection do
      patch :mark_all_read
    end
  end

  resource :subscription, only: [:new, :create, :destroy]

  # Community Routes
  namespace :community do
    resources :feed, only: [:index, :new, :show, :create, :destroy]
    resources :trade_shares, only: [:index, :new, :create, :update]
    resources :leaderboards, only: [:index]
    resources :chat_rooms, only: [:index, :new, :show, :create] do
      resources :messages, only: [:index, :create]
    end
    resources :review_requests, only: [:index, :new, :create, :update, :destroy]
    resources :classrooms, only: [:index, :new, :show, :create] do
      member do
        patch :enroll
      end
    end
    resources :resources, only: [:index, :new, :show, :create]
    get :widget, to: "widgets#embed"
    get "profile/:id", to: "profiles#show", as: :public_profile
  end

  namespace :admin do
    root "users#index"
    resources :users
    post "update_ai_settings", to: "users#update_ai_settings", as: :update_ai_settings
    post "test_ai_connection", to: "users#test_ai_connection", as: :test_ai_connection
  end
end