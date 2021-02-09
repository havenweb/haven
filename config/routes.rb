Rails.application.routes.draw do

  get 'login_links/validate'
  get 'markdown', to: 'static#markdown'
  get 'themes', to: 'static#themes'

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

  post '/posts/:post_id/comments', to: 'comments#create', as: 'create_comment'
  delete '/comments/:comment_id', to: 'comments#destroy', as: 'destroy_comment'

  get 'settings', to: 'settings#show'
  get 'settings/edit', to: 'settings#edit'
  patch 'settings', to: 'settings#update'
  post 'settings/edit', to: 'settings#update'
  get 'css/:hash/style.css', to: 'settings#style'
  get 'css/:hash/fonts.css', to: 'settings#show_fonts'

  get 'settings/font', to: 'settings#edit_fonts', as: "edit_fonts"
  post 'settings/font', to: 'settings#create_font', as: "create_font"
  delete 'settings/font/:font_id', to: 'settings#destroy_font', as: "destroy_font"

  get 'import_posts', to: 'posts#new_import'
  post 'import_posts', to: 'posts#import'

  get 'rss', to: 'posts#rss'

  get 'login_links/validate', as: :login_link

  root 'welcome#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
