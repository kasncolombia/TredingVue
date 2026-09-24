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
    member do
      get :chart_data
    end
    collection do
      get  :import
      post :import_csv
    end
  end

  resources :strategies

  resource :analytics, only: [:show]

  # Legacy Redirects
get 'pro-tools', to: redirect('/prop_firm_accounts')
get 'prop_firms', to: redirect('/prop_firm_accounts')
get 'backtester', to: redirect('/backtesting')

resources :prop_transactions, path: 'prop-firms/transacciones', only: [:index, :create, :destroy], as: :prop_ledger

namespace :backtesting do
  root to: 'dashboard#index'
  resources :sessions, only: [:new, :create, :show] do
    member do
      get :replay
      post :play
      post :pause
      post :next
      post :step_back
      post :change_timeframe
      post :finish
      post :record_trade
      get :historical_data
    end
  end
end

  resources :prop_firm_accounts do
    collection do
      get :templates_json
    end
    member do
      patch :mark_burned
      patch :reset_account
      patch :move_to_funded
    end
  end
  resources :trading_accounts do
    collection do
      get :wizard
      get :brokers_json
    end
  end

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