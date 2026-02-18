Rails.application.routes.draw do
  # Mount Sidekiq web UI (requires authentication in production)
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq' if Rails.env.development?
  
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

      # Office management routes (admin only)
      resources :offices do
        member do
          post 'activate'
          post 'deactivate'
        end
      end

      # Customer management routes
      resources :customers, only: [:index, :show, :create, :update, :destroy]

      # Package and Addon management routes
      resources :packages do
        resources :checklist_items, only: [:index], controller: 'package_checklist_items' do
          collection do
            post ':checklist_item_id', action: :create
            delete ':checklist_item_id', action: :destroy
          end
        end
      end
      resources :addons
      resources :checklist_items

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
          post 'track_travel'
        end
        collection do
          get 'calendar'
        end
      end

      # Route calculation
      post 'routes/calculate', to: 'routes#calculate'

      # Agent specific routes
      namespace :agent do
        resource :attendance, only: [:create] do
          get 'today'
        end
        resource :eod_report, only: [:create] do
          get 'today'
        end
      end
    end
  end

  # Health check route
  get 'health', to: proc { [200, {}, ['OK']] }
end
