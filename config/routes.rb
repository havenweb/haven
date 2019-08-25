Rails.application.routes.draw do
  devise_for :users
  get 'welcome/index'

  resources :posts

  get 'settings', to: 'settings#show'
  get 'settings/edit', to: 'settings#edit'
  patch 'settings', to: 'settings#update'
  post 'settings/edit', to: 'settings#update'
  get 'style.css', to: 'settings#style'

  root 'welcome#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
