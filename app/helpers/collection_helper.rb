module CollectionHelper

  def link_to_collection( collection )
  
    link = collection['title_tesim'].first.to_s

    if current_user.admin?
      link += " - " + collection[ "owner_tesim" ].first unless collection[ "owner_tesim" ].nil?
    end

    link_to( link, dil_collection_path( collection[ 'id' ] ) )
  
  end

end