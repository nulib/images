module Blacklight::SolrHelpers::ObjectTypeFacet

  def multiresimage_object_type_facet(solr_parameters, user_parameters)
    #solr_parameters[:fq] ||= []

        # Only apply this if the search is happening from inside the Hydra app.
        # External searches need Works and Images (Hydra app just needs Images).
    #if (self.class.name != "ExternalSearchController")
      #solr_parameters[:fq] << 'object_type_facet:(Multiresimage) OR active_fedora_model_ssi:(InstitutionalCollection)'
      #solr_parameters[:fq] << 'active_fedora_model_ssi:(InstitutionalCollection)'
    #end
  end
  def institutional_collection_object_type_facet(solr_parameters, user_parameters)
    #solr_parameters[:fq] ||= []

        # Only apply this if the search is happening from inside the Hydra app.
        # External searches need Works and Images (Hydra app just needs Images).
    #if (self.class.name != "ExternalSearchController")
      #solr_parameters[:fq] << 'object_type_facet:(Multiresimage) OR active_fedora_model_ssi:(InstitutionalCollection)'
      #solr_parameters[:fq] << 'active_fedora_model_ssi:(InstitutionalCollection)'
    #end
  end

end
