Rails.application.routes.draw do
  scope ':locale', locale: /#{I18n.available_locales.join("|")}/ do
    post '/users', to: 'users#create'

    devise_for :users,
               controllers: {
                 confirmations: 'users/confirmations',
                 omniauth: 'users/omniauth',
                 passwords: 'users/passwords',
                 registrations: 'users/registrations',
                 sessions: 'users/sessions',
                 unlocks: 'users/unlocks'
               },
               path_names: {sign_in: 'login', sign_out: 'logout'},
               constraints: { format: :html }

    match '/admin', :to => 'admin#index', :as => :admin, :via => :get
    namespace :admin do
      resources :users, constraints: { format: :html }
      resources :page_contents, constraints: { format: :html }
      resources :media, constraints: { format: :html }
    end

    get '/explore/:nameable_type/:nameable_id',
        to: 'root#temp_nameable_show',
        as: 'nameable'

    root 'root#index'
    get '/about' => 'root#about'
    get '/list' => 'root#list'
    get '/csv/complete_primary_finances' => 'csv#complete_primary_finances'

    scope module: :api do
      namespace :v1 do
        resources :page_contents, only: :show, constraints: { format: :json }
        resources :media, only: :index, constraints: { format: :json }
        get '/last_updated_date' => 'last_updated_date#index'

        get '/budget_items/:id' => 'budget_items#show'
        get '/programs' => 'budget_items#programs'
        get '/spending_agencies' => 'budget_items#spending_agencies'
        get '/priorities' => 'budget_items#priorities'
      end
    end

    # handles /en/fake/path/whatever
    get '*path', to: redirect("/#{I18n.default_locale}")
  end

  # handles /
  get '', to: redirect("/#{I18n.default_locale}")

  # handles /not-a-locale/anything
  get '*path', to: redirect("/#{I18n.default_locale}/%{path}")
end
