Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'auth/login', to: 'authentication#login'
      delete 'auth/logout', to: 'authentication#logout'
      get 'auth/me', to: 'authentication#me'

      # User management routes (admin only for create)
      resources :users, only: [:index, :show, :create, :update, :destroy] do
        member do
          post 'lock'
          post 'unlock'
          put 'role', to: 'users#update_role'
        end
      end

      # Customer management routes
      resources :customers, only: [:index, :show, :create, :update, :destroy]
    end
  end

  # Health check route
  get 'health', to: proc { [200, {}, ['OK']] }
end
