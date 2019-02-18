Rails.application.routes.draw do
  resources :tests, only: [:show] do
    collection do
      get :upload
      post :import
    end
  end
end
