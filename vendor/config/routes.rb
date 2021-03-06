require "sidekiq/web"

Rails.application.routes.default_url_options[:host] = Rails.application.secrets.host

Rails.application.routes.draw do

  root "admins/events#index"
  get "/admins", to: "admins/events#index", as: :admin_root
  get ":event_id", to: "events/events#show", as: :customer_root
  get "/admins/sign_in" => redirect("admins/users/sign_in")
  get "/api/v1/events", to: redirect("404.html")
  patch "/api/v2/events/pure-and-crafted-jhb/stations/5980/products", to: redirect("404.html")

  mount ActionCable.server => '/cable'

  #----------------------------------------------------------
  # Admin panel
  #----------------------------------------------------------
  devise_for :users, controllers: { sessions: "admins/sessions", passwords: "admins/passwords"}

  namespace :admins do

    resources :users do
      put :accept_invitation
      delete :refuse_invitation
      resource :team, controller: "users/teams" do
        resources :devices, controller: "users/teams/devices"

        post :add_users
        put :change_role
        delete  :remove_devices
        delete :remove_users
        get :move_devices
        patch :update_devices
      end
    end

    namespace :bizzabo do
      get :auth
    end

    namespace :eventbrite do
      get :auth
    end

    namespace :stubhub do
      get :auth
    end

    namespace :qwantiq do
      get :auth
    end

    namespace :universe do
      get :auth
      post :webhooks
    end

    resources :locale do
      get :change, on: :member
    end

    authenticate :user, lambda { |u| u.admin? } do
      mount Sidekiq::Web => '/sidekiq'
    end



    resources :api_metrics, only: [:index, :show]

    resources :event_series do
      member do
        put :add_event
        delete :remove_event
        get :copy_data
        post :copy_serie
      end
    end

    resources :events do
      get :sample_event, on: :collection

      member do
        delete :remove_db
        get :launch
        get :close
        post :remove_logo
        post :remove_background
        get :create_admin
        get :create_customer_support
        get :refund_fields
        get :zoho_report
        patch :activate_online_topups
      end

      scope module: :events do
        resources :credits do              
          put :sort, on: :collection
        end
        resource :settings, only: :show
        resources :admissions, only: [:index] do
          get :merge, on: :member
        end

        resources :operators, only: [:index] do
          get :merge, on: :member
        end

        authenticate :user do # Needed to be able to use 'include ActionController::Live' in controllers and extra security
          resource :analytics do
            get :dashboard
            get :cash_flow
            get :credits_flow
            get :tokens_flow
            get :checkin
            get :engagement
            get :access_control
            get :partner_reports
            get :sub_report
            get :custom_seasplash
            get :custom_voucher
            get :custom_lambeth
          end
        end

        resource :custom_analytics do
          get :money
          get :download_raw_data
          get :credits
          get :download_raw_data_credits
          get :sales
          get :download_raw_data_sale
          get :checkin
          get :download_raw_data_checkin
          get :access
          get :download_raw_data_access
          get :access_ticket_type
          get :download_raw_data_access_ticket_type
          get :engagement
          get :download_raw_data_engagement
        end

        resources :control_gates, only: [:index]

        resources :alerts, only: [:index, :update, :destroy] do
          get :read_all, on: :collection
        end

        resources :refunds, only: [:index, :show, :destroy, :update]
        resources :orders, only: [:index, :show, :new, :create, :destroy] do
          resources :order_items, only: :update
        end

        resources :gtag_assignments, only: :destroy
        authenticate :user do # Needed to be able to use 'include ActionController::Live' in controllers and extra security
          resources :ticket_types do
            get :unban, on: :member
          end
        end
        resources :device_registrations, only: [:index, :show, :destroy, :new, :create, :update] do
          get :download_db, on: :member
          get :transactions, on: :member
          put :disable, on: :collection
        end

        resources :catalog_items, only: :update

        resources :accesses do
          get :capacity, on: :member
          get :ticket_type, on: :member
        end

        resources :devices, only: [:new, :create]
        resources :device_caches, only: :destroy
        resources :operator_permissions
        resources :packs do
          post :clone, on: :member
        end

        resources :ticket_assignments, only: :destroy
        resources :event_registrations, except: :show
        resources :event_invitations, except: [:show, :index] do
          get :resend, on: :member
          get :accept, on: :member
        end

        resources :ticketing_integrations do
          get :activate, on: :member
          get :deactivate, on: :member

          # Bizzabo
          get "bizzabo", to: "bizzabo#index"
          get "bizzabo/import_tickets", to: "bizzabo#import_tickets"
          get "bizzabo/connect/:p4_uuid", to: "bizzabo#connect", as: "bizzabo_connect"

          # Eventbrite
          get "eventbrite", to: "eventbrite#index"
          get "eventbrite/import_tickets", to: "eventbrite#import_tickets"
          get "eventbrite/connect/:eb_event_id", to: "eventbrite#connect", as: 'eventbrite_connect'
          post "eventbrite/webhooks", to: "eventbrite#webhooks"

          # Universe
          get "universe", to: "universe#index"
          get "universe/import_tickets", to: "universe#import_tickets"
          get "universe/connect/:uv_event_id", to: "universe#connect", as: 'universe_connect'

          # Stubhub
          get "stubhub", to: "stubhub#index"
          get "stubhub/import_tickets", to: "stubhub#import_tickets"
          get "stubhub/connect/:p4_uuid", to: "stubhub#connect", as: "stubhub_connect"

          # Qwantiq
          get "qwantiq", to: "qwantiq#index"
          get "qwantiq/import_tickets", to: "qwantiq#import_tickets"
          get "qwantiq/connect/:p4_uuid", to: "qwantiq#connect", as: "qwantiq_connect"

          # TicketMaster
          get "ticket_master", to: "ticket_master#index"
          get "ticket_master/import_tickets", to: "ticket_master#import_tickets"
          get "ticket_master/connect", to: "ticket_master#connect", as: "ticket_master_connect"
          delete "ticket_master/destroy", to: "ticket_master#destroy", as: "ticket_master_destroy"
        end

        authenticate :user do # Needed to be able to use 'include ActionController::Live' in controllers and extra security
          resources :pokes, only: [:index, :show] do
            get :download, on: :collection
          end
        end

        resources :payment_gateways, except: :show

        resources :customers, only: [:index, :show, :edit, :update] do
          member do
            resources :ticket_assignments, only: [:new, :create]
            resources :gtag_assignments, only: [:new, :create]
            get :download_transactions
            get :reset_password
            get :resend_confirmation
            get :confirm_customer
            get :merge
            get :edit_pokes
          end
          collection do
            get :sample_csv
            post :import
          end
        end

        resources :gtags do
          member do
            get :recalculate_balance
            get :solve_inconsistent
            get :merge
            get :make_active
          end
          collection do
            get :inconsistencies
            get :missing_transactions
            get :sample_csv
            post :import
          end
        end

        resources :tickets do
          member do
            get :ban
            get :unban
            get :merge
          end
          collection do
            get :sample_csv
            post :import
          end
        end

        authenticate :user do # Needed to be able to use 'include ActionController::Live' in controllers and extra security
          resources :stations do
            post :clone
            post :hide
            post :unhide
            put :add_ticket_types
            put :remove_ticket_types
            get :analytics
            scope module: :stations do
              resources :products, only: [:update, :index] do
                collection do
                  get :sample_csv
                  post :import
                end
              end
              resources :station_items, only: [:create, :update, :destroy] do
                put :sort, on: :collection
                get :find_product, on: :collection
              end
            end
          end
        end

      end
    end
  end

  #----------------------------------------------------------
  # Customer Area
  #----------------------------------------------------------
  devise_for :customers, skip: [:session, :password, :registration, :confirmation], controllers: { omniauth_callbacks: "events/omniauth_callbacks", confirmations: 'confirmations'}

  scope module: "events" do
    resources :events, only: [:show], path: "/" do
      devise_for :customers, skip: :omniauth_callbacks

      devise_scope :customer do
        get "/login", to: "sessions#new"
        post "/login", to: "sessions#create"
        delete "/logout", to: "sessions#destroy"
        get "/resend_confirmation", to: "sessions#resend_confirmation"
        post "/send_email", to: "sessions#send_email"
        get "/register", to: "registrations#new"
        get "/account", to: "registrations#edit"
        get "/change_password", to: "registrations#change_password"
        patch "/update_password", to: "registrations#update_password"
        post "/register", to: "registrations#create"
        patch "/register", to: "registrations#update"
        get "/recover_password", to: "passwords#new"
        post "/recover_password", to: "passwords#create"
        get "/edit_password", to: "passwords#edit"
        patch "/edit_password", to: "passwords#update"
      end

      get "signin", to: "registrations#new"
      get "login", to: "sessions#new"
      delete "logout", to: "sessions#destroy"

      resources :locale do
        member do
          get "change"
        end
      end

      resources :ticket_assignments, only: [:new, :create, :destroy]
      resources :gtag_assignments, only: [:new, :create]
      resources :tickets, only: [:show]
      resources :gtags, only: [:show] do
        patch :ban, on: :member
      end
      resources :orders, only: [] do
        get :success, on: :member
        get :error, on: :member
        get :abstract_error, on: :collection
      end

      get :credits_history, to: "credits_histories#history"
      get :privacy_policy, to: "static_pages#privacy_policy"
      get :terms_of_use, to: "static_pages#terms_of_use"

      # Bank Account
      resources :refunds
    end
  end

  #----------------------------------------------------------
  # API
  #----------------------------------------------------------
  namespace :api, defaults: { format: "json" } do

    # V2
    #---------------
    namespace :v2 do
      resources :users, except: [:show, :index, :update, :new, :edit, :create] do
        post :can_login, on: :collection
      end

      resources :events, only: [:show, :index, :update] do
        scope module: "events" do
          resources :accesses

          resources :tickets do
            resources :pokes, only: [:index]

            post :create_sonar_operator, on: :collection
            member do
              post :topup
              post :virtual_topup
              post :ban
              post :unban
            end
          end

          resources :gtags do
            resources :pokes, only: [:index]

            member do
              post :replace
              post :topup
              post :virtual_topup
              post :ban
              post :unban
            end
          end

          resources :customers, constraints: { id: /.*/ } do
            resources :pokes, only: [:index]

            member do
              post :ban
              post :unban
              post :topup
              post :virtual_topup
              post :assign_gtag
              post :assign_ticket
              post :gtag_replacement
              post :refund
              post :can_login
              get :refunds
              get :transactions
              get :store_redirection
            end
          end

          resources :stations do
            resources :products
          end

          resources :refunds do
            put :complete, on: :member
            put :cancel, on: :member
          end

          resources :orders, except: %i[create update] do
            put :complete, on: :member
          end

          resources :ticket_types do
            get :tickets, on: :member
            post :bulk_upload, on: :member
          end

          namespace :analytics do
            get 'credits/:action_method', to: 'credit_analytics#index'
            get 'money/:action_method', to: 'money_analytics#index'
            get 'access/:action_method', to: 'access_analytics#index'
          end
        end
      end
    end

    # V1
    #---------------
    namespace :v1 do
      resources :device, only: [:create] do
        get :show, on: :collection
      end
      resources :events, only: [] do
        scope module: "events" do
          resource :database, only: [:create, :show]
          resources :accesses, only: :index
          resources :operator_permissions, only: :index
          resources :auto_top_ups, only: :create
          resources :backups, only: :create
          resources :ticket_types, only: :index
          resources :credits, only: :index
          resources :customers, only: [:index, :show]
          resources :orders, only: :index
          resources :packs, only: :index
          resources :parameters, only: :index
          resources :products, only: :index
          resources :stations, only: :index
          resources :transactions, only: :create
          resources :device_transactions, only: :create
          resources :user_flags, only: :index
          resources :tickets, only: [:index, :show], constraints: { id: /.*/ } do
            get :banned, on: :collection
          end
          resources :gtags, only: [:index, :show] do
            get :banned, on: :collection
          end
          get "/time", to: "time#index"
        end
      end
    end
  end


  ##----------------------------------------------------------
  # Thirdparty API
  #----------------------------------------------------------
  namespace :companies do
    namespace :api, defaults: { format: "json" } do
      namespace :v1 do
        resources :banned_tickets, path: "tickets/blacklist", only: [:index, :create, :destroy]
      end
    end
  end
end
