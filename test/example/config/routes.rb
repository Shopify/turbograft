Rails.application.routes.draw do
  root to: 'pages#show'
  resources :pages, :only => [:index, :show, :new] do
    collection do
      get :html_with_noscript
      get :error_500
      get :error_404
      get :error_422
      get :error_422_with_show
      post :redirect_to_somewhere_else_after_POST
      post :post_foo
      put :put_foo
      patch :patch_foo
      delete :delete_foo
    end
  end
end
