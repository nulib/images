module Blacklight::SolrHelpers::ObjectTypeFacet

  def multiresimage_object_type_facet(solr_parameters, user_parameters)
    solr_parameters[:q] ||= []

        # Only apply this if the search is happening from inside the Hydra app.
        # External searches need Works and Images (Hydra app just needs Images).
    if (self.class.name != "ExternalSearchController")
      solr_parameters[:q] << 'object_type_facet:Multiresimage'
    end
    #solr_parameters[:q] << 'default_search_t:'.params[:q]
  end

end
