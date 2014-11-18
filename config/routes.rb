Rails.application.routes.draw do
  Blacklight.add_routes(self)
  HydraHead.add_routes(self)
  Hydra::BatchEdit.add_routes(self)

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    root "catalog#index"
  end

  resources :multiresimages do
    collection do
      get 'aware_tile'
      get 'aware_details'
      post 'add_datastream'
      post 'add_external_datastream'
      post 'menu_publish'
      post 'create_update_fedora_object'
      delete 'delete_fedora_object'
      post 'clone_work'
      post 'create_crop'
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

  resources :uploads do
    collection do
      post :enqueue
      post :create
      post :update_status
      post :notify
    end
  end

  resources :groups do
    resources :users, :only=>[:create, :edit, :destroy]
  end


  get "multiresimages/svg/:id" => "multiresimages#get_svg"
  get "multiresimages/get_image/:id/:image_length" => "multiresimages#proxy_image"
  get "multiresimages/archival_image_proxy/:id" => "multiresimages#archival_image_proxy"
  patch "multiresimages/updatecrop/:id" => "multiresimages#updatecrop"

  get "dil_collections/:pid/:id/:index" => "multiresimages#show", :constraints=> { pid: /inu.*/ }
  get "dil_collections/:pid/:id" => "multiresimages#show", :constraints=> { pid: /inu.*/ }
  get "dil_collections/get_subcollections/:id" => "dil_collections#get_subcollections" , :defaults => { :format => 'json' }
  post "dil_collections/add/:id/:member_id" => "dil_collections#add"
  post "dil_collections/remove/:id/:pid" => "dil_collections#remove"
  post "dil_collections/move/:id/:from_index/:to_index" => "dil_collections#move"
  post "dil_collections/export/:id" => "dil_collections#export"
  post "dil_collections/add_to_batch_select/:id" => "dil_collections#add_to_batch_select" , :defaults => { :format => 'json' }
  post "dil_collections/remove_from_batch_select/:id" => "dil_collections#remove_from_batch_select" , :defaults => { :format => 'json' }
  post "dil_collections/make_private/:id" => "dil_collections#make_private"
  post "dil_collections/make_public/:id" => "dil_collections#make_public"
  # post "dil_collections/new" => "dil_collections#new" #there is no 'new' action

  get "groups/edit/:id" => "groups#edit"

  get "external_search/search_hydra" => "external_search#index"

  get 'technical_metadata/:id/:type.:format' => 'technical_metadata#show', :as => :technical_metadata, :constraints=>{:type => /[\w-]+/, :id=>/[\w:-]+/}

end
