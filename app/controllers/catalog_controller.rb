require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Catalog
  include Blacklight::SolrHelpers::ObjectTypeFacet

  # These before_filters apply the hydra access controls
  before_filter :enforce_access_controls
  before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params
  #debugger
  #test = request.remote_ip
  CatalogController.solr_search_params_logic << :multiresimage_object_type_facet

def enforce_facet_permissions
end


end 

