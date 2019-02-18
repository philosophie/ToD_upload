Rails.application.routes.draw do
  resources :tests do
    collection do
      get :upload
      post :import
    end
  end
end
