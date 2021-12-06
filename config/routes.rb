Rails.application.routes.draw do
  
  resources :variations
  get 'home/index'
  devise_for :users
  devise_for :admins
  
  authenticate :admin do
    resources :products
    resources :categories

  end

  # Recurso particular porque no depende del id, depende del usuario actual
  resource :cart, only: [:show, :update] do
    member do
      post :pay_with_paypal
      get :process_paypal_payment
    end
  end
  
  root to: "home#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
