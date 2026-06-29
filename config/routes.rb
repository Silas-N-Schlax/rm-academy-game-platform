Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check


  resources :games, only: [ :index ]
  get "games/history", to: "games#history"

  resources :pages, only: [ :index ]
  get "pages/rules", to: "pages#rules"

  resources :stats, only: [ :index ]
  get "stats", to: "stats#index"

  root "games#index"
end
