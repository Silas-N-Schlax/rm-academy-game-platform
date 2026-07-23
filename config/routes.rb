Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "up" => "rails/health#show", as: :rails_health_check

  concern :turbo_fetch do
    patch :turbo_fetch, on: :collection
  end

  mount GoodJob::Engine => "good_job"


  resources :games, only: [ :index, :new, :create, :show ] do
    resources :turns, only: [ :create ]
    resources :players, only: [ :create ]
    collection { get :history }
  end

  resources :rules, only: [ :index, :show ]

  resources :stats, only: [ :index ]
  get "stats", to: "stats#index"

  resources :users, only: [ :new, :create, :update, :edit ], concerns: %i[turbo_fetch]
  get "users/show", to: "users#show"


  resources :offline, only: [ :index ]

  resources :board_preview, only: [ :index ]

  root "games#index"
end
