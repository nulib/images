class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  # This applies appropriate access controls to all solr queries
  self.default_processor_chain += [:add_access_controls_to_solr_params]
  self.default_processor_chain << :multiresimage_object_type_facet

end
