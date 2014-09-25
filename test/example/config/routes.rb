Rails.application.routes.draw do
  root to: 'pages#show'
  resources :pages, :only => [:index, :show, :new] do
    collection do
      get :html_with_noscript
      get :error_500
      get :error_404
      post :redirect_to_somewhere_else_after_POST
    end
  end
end
