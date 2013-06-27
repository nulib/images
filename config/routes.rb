DIL::Application.routes.draw do
  Blacklight.add_routes(self)
  HydraHead.add_routes(self)
  Hydra::BatchEdit.add_routes(self)

  authenticated :user do
    root :to => "catalog#index"
  end

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    root :to => "devise/sessions#new"
  end
  
  #NEED TO REFACTOR THESE ROUTES - RAILS 2 and RAILS 3 routes
  
  resources :multiresimages do
    collection do
      get 'aware_tile'
      post 'add_datastream'
      post 'add_external_datastream'
      #TODO change to post or delete
      get 'delete_fedora_object'
      get 'clone_work'
      post 'create_crop'
      get 'get_pids_from_accession_number'
    end
    member do
      post 'permissions'
    end
  end
  
  resources :dil_collections do
    collection do
      get "get_collections"=>"dil_collections#get_collections"
    end
  end
  
  match "multiresimages/create_update_fedora_object" => "multiresimages#create_update_fedora_object", :via => :post
  #match "multiresimages/create_crop/:id" => "multiresimages#create_crop", :via => :get
  match "multiresimages/updatecrop/:id" => "multiresimages#updatecrop"
  match "multiresimages/svg/:id" => "multiresimages#get_svg"
  match "multiresimages/aware_details" => "multiresimages#aware_details"
  match "multiresimages/get_image/:id/:image_length" => "multiresimages#proxy_image"
  match "external_search/search_hydra" => "external_search#index"
  match "dil_collections/add/:id/:member_id" => "dil_collections#add", :via => :post
  match "dil_collections/remove/:id/:pid" => "dil_collections#remove", :via => :post
  match "dil_collections/new" => "dil_collections#new", :via => :post
  match "dil_collections/move/:id/:from_index/:to_index" => "dil_collections#move", :via => :post
  match "dil_collections/export/:id" => "dil_collections#export", :via => :post
  match "dil_collections/get_subcollections/:id" => "dil_collections#get_subcollections" , :defaults => { :format => 'json' }
  match "dil_collections/add_to_batch_select/:id" => "dil_collections#add_to_batch_select" , :defaults => { :format => 'json' }, :via => :post
  match "dil_collections/remove_from_batch_select/:id" => "dil_collections#remove_from_batch_select" , :defaults => { :format => 'json' }, :via => :post
  
  resources :uploads, :only => [:index] do
    collection do
      post :enqueue
    end
  end
  match "uploads/create" => "uploads#create"
  match "uploads/update_status" => "uploads#update_status"

  resources :groups do
    resources :users, :only=>[:create, :destroy]
  end

#  resources :policies

  resources :technical_metadata, :only=>:index

  match 'technical_metadata/:id/:type.:format' => 'technical_metadata#show', :as => :technical_metadata, :constraints=>{:type => /[\w-]+/, :id=>/[\w:-]+/}

  
end
