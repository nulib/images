MyHydraHead::Application.routes.draw do
  Blacklight.add_routes(self)
  HydraHead.add_routes(self)

  root :to => "catalog#index"

  devise_for :users
  
  resources :multiresimages do
    collection do
      get 'aware_tile'
      post 'create_update_fedora_object'
      post 'add_datastream'
      post 'add_external_datastream'
      get 'delete_fedora_object'
      get 'clone_work'
    end
  end
  
  resources :dil_collections
  
  #match "multiresimages/updatecrop/:id", :controller=>'multiresimages', :action=>'updatecrop'
  #match "multiresimages/create", :controller=>'multiresimages', :action=>'create'
  #match "multiresimages/svg/:id", :controller=>'multiresimages', :action=>'get_svg'
  #match "multiresimages/aware_details", :controller=>'multiresimages', :action=>'aware_details'
  ##match "multiresimages/aware_tile", :controller=>'multiresimages', :action=>'aware_tile'
  #match "multiresimages/aware_tile/:file_path/:x/:y/:level", :controller=>'multiresimages', :action=>'aware_tile'
  #match "uploads/create", :controller=> 'uploads', :action=>'create'
  
  match "multiresimages/updatecrop/:id" => "multiresimages#updatecrop"
  #match "multiresimages/create" => "multiresimages#create"
  match "multiresimages/svg/:id" => "multiresimages#get_svg"
  match "multiresimages/aware_details" => "multiresimages#aware_details"
  #match "multiresimages/aware_tile", :controller=>'multiresimages', :action=>'aware_tile'
  #match "multiresimages/aware_tile" => "multiresimages#aware_tile"
  match "external_search/search_hydra" => "external_search#index"
  match "uploads/create" => "uploads#create"
  match "uploads/test" => "uploads#test"
  match "uploads/update_status" => "uploads#update_status"
  match "dil_collections/add/:id/:member_id" => "dil_collections#add"
  match "dil_collections/remove/:id/:member_index" => "dil_collections#remove"
  match "dil_collections/new" => "dil_collections#new"
  match "dil_collections/move/:id/:from_index/:to_index" => "dil_collections#move"
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
