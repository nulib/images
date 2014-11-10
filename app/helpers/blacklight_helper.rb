

module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior


  # I'm not sure if we need this method right now - CS 11-10-14
  # def search_action_url
  #   catalog_index_url
  # end



  # NOTE: the only difference in this call is my_params.delete(:id), i'm not sure why it exists
  # so i'm going to leave this method in for now

  # Create form input type=hidden fields representing the entire search context,
  # for inclusion in a form meant to change some aspect of it, like
  # re-sort or change records per page. Can pass in params hash
  # as :params => hash, otherwise defaults to #params. Can pass
  # in certain top-level params keys to _omit_, defaults to :page
  def search_as_hidden_fields(options={})
    my_params = params_for_search({:omit_keys => [:page]}.merge(options))
    my_params.delete(:id)
    # hash_as_hidden_fields in hash_as_hidden_fields.rb
    return hash_as_hidden_fields(my_params)
  end



end