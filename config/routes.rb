Rails.application.routes.draw do

  blacklight_for :catalog

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }


  get "/multiresimages/get_vra/", to: "multiresimages#get_vra"

  devise_scope :user do
    root "catalog#index"
  end


  #putting this in for testing menu vra edit == JL 
 

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
      get 'get_pids_from_accession_number', :defaults => { :format => 'xml' }
      get 'get_number_of_objects', :defaults => { :format => 'xml' }
    end
    member do
      post 'permissions'
      # get 'svg'
      # get 'get_image'
      # get 'archival_image_proxy'
      # patch 'updatecrop'
    end
  end

  # resources :dil_collections do
  #   collection do
  #     get "get_collections"
  #   end
  #   member do
  #     get 'get_subcollections'
  #     # post 'add'
  #     # post 'remove'
  #     # post 'move'
  #     # post 'export'
  #     # post 'add_to_batch_select'
  #     # post 'remove_from_batch_select'
  #     # post 'make_private'
  #     # post 'make_public'
  #   end
  # end

  resources :groups do
    resources :users, :only=>[:create, :edit, :destroy]
  end

  # The routes below aren't resourceful, but I'm not sure if anything outside of the application is referring to them
  # so I don't want to refactor them into resourceful routes. I created placeholders for them above though - CS 11-18-2014
  
  get "multiresimages/svg/:id" => "multiresimages#get_svg"
  get "multiresimages/get_image/:id/:image_length" => "multiresimages#proxy_image"
  get "multiresimages/archival_image_proxy/:id" => "multiresimages#archival_image_proxy"
  patch "multiresimages/updatecrop/:id" => "multiresimages#updatecrop"

  get "dil_collections/:pid/:id/:index" => "multiresimages#show", :constraints=> { pid: /inu.*/ }
  get "dil_collections/:pid/:id" => "multiresimages#show", :constraints=> { pid: /inu.*/ }

  get "dil_collections/get_subcollections/:id" => "dil_collections#get_subcollections" , :defaults => { :format => 'json' }
  post "dil_collections/add/:id/:member_id" => "dil_collections#add"
  delete "dil_collections/remove/:id/:pid" => "dil_collections#remove"
  post "dil_collections/move/:id/:from_index/:to_index" => "dil_collections#move"
  post "dil_collections/export/:id" => "dil_collections#export"
  post "dil_collections/add_to_batch_select/:id" => "dil_collections#add_to_batch_select" , :defaults => { :format => 'json' }
  post "dil_collections/remove_from_batch_select/:id" => "dil_collections#remove_from_batch_select" , :defaults => { :format => 'json' }
  post "dil_collections/make_private/:id" => "dil_collections#make_private"
  post "dil_collections/make_public/:id" => "dil_collections#make_public"

  get "groups/edit/:id" => "groups#edit"

  get "external_search/search_hydra" => "external_search#index"

  get 'technical_metadata/:id/:type.:format' => 'technical_metadata#show', :as => :technical_metadata, :constraints=>{:type => /[\w-]+/, :id=>/[\w:-]+/}

end
