Rails.application.routes.draw do
  root to: 'pages#show'
  resources :pages, :only => :show
end
