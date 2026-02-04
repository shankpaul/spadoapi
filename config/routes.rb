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

      # Package and Addon management routes
      resources :packages
      resources :addons

      # Subscription management routes
      resources :subscriptions do
        member do
          post 'pause'
          post 'resume'
          post 'cancel'
          post 'update_payment'
          get 'orders'
        end
      end

      # Order management routes
      resources :orders do
        member do
          post 'assign'
          post 'reassign'
          post 'update_status'
          patch 'status', to: 'orders#update_status'
          post 'cancel'
          post 'feedback'
          get 'reassignments'
          get 'timeline'
        end
        collection do
          get 'calendar'
        end
      end
    end
  end

  # Health check route
  get 'health', to: proc { [200, {}, ['OK']] }
end
