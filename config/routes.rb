require 'sidekiq/pro/web'

Rails.application.routes.draw do

  blacklight_for :catalog
  mount Riiif::Engine => '/image-service', as: 'riiif'

  if Rails.env.staging? or Rails.env.remote_dev?
    mount AboutPage::Engine => '/about(.:format)'
  end

  if Rails.env.test?
    match 'ouch', :to => 'application#test500', via: [ :get, :post, :patch, :delete ]
    match "error", :to => "application#page_not_found", via: [ :get, :post, :patch, :delete ]
  end

  if Rails.env.production?
     get '404', :to => 'application#page_not_found'
     get '422', :to => 'application#server_error'
     get '500', :to => 'application#server_error'
  end

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  get "/multiresimages/get_vra/", to: "multiresimages#get_vra"

  devise_scope :user do
    root "catalog#index"
  end

  resources :multiresimages do
    collection do
      post 'add_datastream'
      post 'add_external_datastream'
      post 'menu_publish'
      put 'update_vra'
      post 'create'
      delete 'delete_fedora_object'
      post 'clone_work'
      get 'get_pids_from_accession_number', :defaults => { :format => 'xml' }
      get 'get_number_of_objects', :defaults => { :format => 'xml' }
    end
    member do
      post 'permissions'
      # get 'archival_image_proxy'
    end
  end

  resources :dil_collections do
    collection do
      get "get_collections"
    end
    member do
      get 'get_subcollections'
      # post 'add'
      # post 'remove'
      # post 'move'
      # post 'export'
      # post 'add_to_batch_select'
      # post 'remove_from_batch_select'
      # post 'make_private'
      # post 'make_public'
    end
  end

  resources :institutional_collections do
    member do
      get 'add_images'
      get 'images'
      get 'confirm_add_images'
      get 'rights'
      post 'remove_image'
    end
  end

  resources :groups do
    resources :users, :only=>[:create, :edit, :destroy]
  end

  resources :batches
  # The routes below aren't resourceful, but I'm not sure if anything outside of the application is referring to them
  # so I don't want to refactor them into resourceful routes. I created placeholders for them above though - CS 11-18-2014

  get 'technical_metadata/:id/:type' => 'technical_metadata#show', :as => :technical_metadata, :constraints=>{:type => /[\w-]+/, :id=>/[\w:-]+/}

  get "multiresimages/archival_image_proxy/:id" => "multiresimages#archival_image_proxy"

  get "dil_collections/:pid/:id/:index" => "multiresimages#show", :constraints=> { pid: /inu.*/ }
  get "dil_collections/:pid/:id" => "multiresimages#show", :constraints=> { pid: /inu.*/ }

  get "dil_collections/get_subcollections/:id" => "dil_collections#get_subcollections" , :defaults => { :format => 'json' }
  post "dil_collections/add/:id/:member_id" => "dil_collections#add"
  delete "dil_collections/remove/:id/:pid" => "dil_collections#remove"
  post "dil_collections/move/:id/:from_index/:to_index" => "dil_collections#move"
  get "dil_collections/generate_powerpoint/:id" => "dil_collections#generate_powerpoint"
  get "dil_collections/powerpoint_check/:id" => "dil_collections#powerpoint_check"
  post "dil_collections/add_to_batch_select/:id" => "dil_collections#add_to_batch_select" , :defaults => { :format => 'json' }
  post "dil_collections/remove_from_batch_select/:id" => "dil_collections#remove_from_batch_select" , :defaults => { :format => 'json' }
  post "dil_collections/make_private/:id" => "dil_collections#make_private"
  post "dil_collections/make_public/:id" => "dil_collections#make_public"

  get "groups/edit/:id" => "groups#edit"

  get "external_search/search_hydra" => "external_search#index"

end
