# -*- encoding : utf-8 -*-
module Blacklight::SolrHelpers::ObjectTypeFacet

  def multiresimage_object_type_facet(solr_parameters, user_parameters)
    solr_parameters[:q] ||= []
    solr_parameters[:q] << 'object_type_facet:Multiresimage'
  end

end
