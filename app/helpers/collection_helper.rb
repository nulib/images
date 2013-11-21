module CollectionHelper

  # Generates a link to a collection, given the collection object
  def link_to_collection( collection )
  
    # Get the collection title
    link = collection['title_tesim'].first.to_s

    # If the current user is an admin append the collection owner to the title
    if current_user.admin?
      link += " - " + collection[ "owner_tesim" ].first unless collection[ "owner_tesim" ].nil?
    end

    # Generate the link
    link_to( link, dil_collection_path( collection[ 'id' ] ) )
  
  end

end