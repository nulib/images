DIL::Application.routes.draw do
  Blacklight.add_routes(self)
  HydraHead.add_routes(self)
  Hydra::BatchEdit.add_routes(self)


  root :to => "catalog#index"

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  
  resources :multiresimages do
    collection do
      get 'aware_tile'
      post 'add_datastream'
      post 'add_external_datastream'
      get 'delete_fedora_object'
      get 'clone_work'
      get 'create_crop'
      get 'get_pids_from_accession_number'
    end
    member do
      post 'permissions'
    end
  end
  
  resources :dil_collections do
    collection do
      get 'get_subcollections'
    end
  end
  
  #resources :dil_collections  
  
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
