require 'blacklight/catalog'
class CatalogController < ApplicationController  

  include Blacklight::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Controller::ControllerBehavior
  include DIL_Blacklight::SolrHelpers::ObjectTypeFacet

  # These before_filters apply the hydra access controls
  #before_filter :enforce_access_controls
  #before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  # This applies appropriate access controls to all solr queries
  self.solr_search_params_logic += [:add_access_controls_to_solr_params]
  self.solr_search_params_logic << :multiresimage_object_type_facet
  configure_blacklight do |config|
    config.default_solr_params = { 
      :qt => 'search',
      :qf => 'title_display_tesim search_field_tesim', # List all the fields you want to search here
      :rows => 10 
    }

    # solr field configuration for search results/index views
    config.index.show_link = 'title_display'
    config.index.record_display_type = 'has_model_ssim'

    # solr field configuration for document/show views
    config.show.html_title = 'title_display'
    config.show.heading = 'title_display'
    config.show.display_type = 'has_model_ssim'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar
    config.add_facet_field 'agent_name_facet', :label => 'Creator', :limit=>5 
    config.add_facet_field 'culturalContext_facet', :label => 'Cultural Context', :limit=>5 
    config.add_facet_field 'date_display_facet', :label => 'Date', :limit=>5 
    config.add_facet_field 'stylePeriod_facet', :label => 'Style/Period', :limit=>5
    config.add_facet_field 'subject_term_facet', :label => 'Subject', :limit=>5 
    config.add_facet_field 'technique_facet', :label => 'Technique' 
    config.add_facet_field 'worktype_facet', :label => 'Work Type', :limit=>5  

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config.add_index_field 'title_display', :label => 'Title:' 
    config.add_index_field 'title_vern_display', :label => 'Title:' 
    config.add_index_field 'author_display', :label => 'Author:' 


    

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_sort asc', :label => 'relevance'
    config.add_sort_field 'title_sort asc', :label => 'year'
    config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
    #config.add_sort_field 'title_sort asc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def apply_superuser_permissions(permission_types)
    user_access_filters = []
    if current_user.present?
      if current_user.admin?
        permission_types.each do |type|
          user_access_filters << "#{type}_access_person_t:[* TO *]"        
        end
      end
    else
      redirect_to(root_path)
    end
    user_access_filters
  end


end 

