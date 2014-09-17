Rails.application.routes.draw do
  root to: 'pages#show'
  resources :pages, :only => [:index, :show, :new] do
    collection do
      get :html_with_noscript
      get :error_500
      get :error_404
    end
  end
end
