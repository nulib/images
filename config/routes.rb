Rails.application.routes.draw do
  Blacklight.add_routes(self)
  HydraHead.add_routes(self)
  Hydra::BatchEdit.add_routes(self)

  # authenticated :user do
  #   root "catalog#index"
  # end

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    root "catalog#index"
  end

  #NEED TO REFACTOR THESE ROUTES - RAILS 2 and RAILS 3 routes


  resources :multiresimages do
    collection do
      get 'aware_tile'
      get 'aware_details'
      post 'add_datastream'
      post 'add_external_datastream'
      post 'menu_publish'
      post 'create_update_fedora_object'
      #TODO change to post or delete
      get 'delete_fedora_object'
      get 'clone_work'
      get 'create_crop'
      get 'get_pids_from_accession_number', :defaults => { :format => 'xml' }
      get 'get_number_of_objects', :defaults => { :format => 'xml' }
    end
    member do
      post 'permissions'
    end
  end

  resources :dil_collections do
    collection do
      get "get_collections"

    end
    member do

    end
  end


  get "dil_collections/:pid/:id/:index" => "multiresimages#show", :via => :get, :constraints=> { pid: /inu.*/ }
  get "dil_collections/:pid/:id" => "multiresimages#show", :via => :get, :constraints=> { pid: /inu.*/ }

  patch "multiresimages/updatecrop/:id" => "multiresimages#updatecrop"
  get "multiresimages/svg/:id" => "multiresimages#get_svg"
  get "multiresimages/get_image/:id/:image_length" => "multiresimages#proxy_image"
  get "multiresimages/archival_image_proxy/:id" => "multiresimages#archival_image_proxy", :via => :get
  get "external_search/search_hydra" => "external_search#index"
  post "dil_collections/add/:id/:member_id" => "dil_collections#add", :via => :post
  get "dil_collections/remove/:id/:pid" => "dil_collections#remove"#, :via => :post
  post "dil_collections/new" => "dil_collections#new", :via => :post
  post "dil_collections/move/:id/:from_index/:to_index" => "dil_collections#move", :via => :post
  post "dil_collections/export/:id" => "dil_collections#export", :via => :post
  get "dil_collections/get_subcollections/:id" => "dil_collections#get_subcollections" , :defaults => { :format => 'json' }
  post "dil_collections/add_to_batch_select/:id" => "dil_collections#add_to_batch_select" , :defaults => { :format => 'json' }, :via => :post
  post "dil_collections/remove_from_batch_select/:id" => "dil_collections#remove_from_batch_select" , :defaults => { :format => 'json' }, :via => :post
  post "uploads/notify" => "uploads#notify", :via => :post
  post "dil_collections/make_private/:id" => "dil_collections#make_private" , :via => :post
  post "dil_collections/make_public/:id" => "dil_collections#make_public" , :via => :post

  resources :uploads do #, :only => [:index] do
    collection do
      post :enqueue
      post :create
      post :update_status
    end
  end

  resources :groups do
    resources :users, :only=>[:create, :edit, :destroy]
  end
  get "groups/edit/:id" => "groups#edit", :via => :get

#  resources :policies

  #resources :technical_metadata, :only=>:index

  get 'technical_metadata/:id/:type.:format' => 'technical_metadata#show', :as => :technical_metadata, :constraints=>{:type => /[\w-]+/, :id=>/[\w:-]+/}


end
