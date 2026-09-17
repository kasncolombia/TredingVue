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

  resources :trades do
    collection do
      get  :import
      post :import_csv
    end
  end

  resources :strategies

  resource :analytics, only: [:show]

  resource :ai_coach, controller: "ai_coach", only: [:show] do
    post :analyze_trade
    post :chat
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
  end
end