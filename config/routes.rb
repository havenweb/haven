Rails.application.routes.draw do
  devise_for :users, :skip => [:registrations] 
  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users' => 'devise/registrations#update', :as => 'user_registration'
  end

  scope '/admin' do
    resources :users
    post '/users/:id/resetpassword', to: 'users#resetpassword', as: 'reset_user_password'
    post '/users/:id/toggleadmin', to: 'users#toggleadmin', as: 'toggle_user_admin'
  end

  resources :posts

  get 'settings', to: 'settings#show'
  get 'settings/edit', to: 'settings#edit'
  patch 'settings', to: 'settings#update'
  post 'settings/edit', to: 'settings#update'
  get 'css/:hash/style.css', to: 'settings#style'

  root 'welcome#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
