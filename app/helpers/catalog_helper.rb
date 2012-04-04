module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  def get_users_collections(current_user_login)
#    query="_query_:\"{!dismax qf=$qf_dismax pf=$pf_dismax}\"" 
#    query="_query_:\"has_model_s:info\\\\:fedora/afmodel\\\\:HydrangeaCollection\"" 

     query="_query_:\"depositor_t:#{current_user_login} AND has_model_s:info\\\\:fedora/afmodel\\\\:DILCollection\"" 

#    query="_query_:\"has_model_s:info\\\\:fedora/afmodel\\\\:MultiresImage\"" 
#    (response,document_list) = get_search_results( {:q=>query, :fl=>'id has_model_s title_t'} )
#	document_list.inspect
	
#    query="_query_:\"depositor_t:#{current_user_login} AND has_model_s:info\\\\:fedora/afmodel\\\\:HydrangeaArticle\"" 
#    (response, document_list) = get_search_results( {:q=>query, :fl=>'id has_model_s title_t'} )
#	document_list.inspect
#	return (response, document_list)

    solr_response = Blacklight.solr.find({:q=>query, :fl=>'id has_model_s title_t'})

    document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc)}

    return [solr_response, document_list]
  end

end
