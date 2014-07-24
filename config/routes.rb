Rails.application.routes.draw do
  root 'customers#index'

  resources :orders
  resources :customers
end
