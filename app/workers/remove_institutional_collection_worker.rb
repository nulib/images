class RemoveInstitutionalCollectionWorker
  include Sidekiq::Worker

  def perform(current_collection_id)
    current_collection = InstitutionalCollection.find(current_collection_id)
    target_collection = InstitutionalCollection.find("inu:dil-00-23655b1f-7029-4fb4-aa10-8ababe0ca63b") # DIL COLLECTION

    member_images = get_member_images(current_collection)

    # Change the :is_governed_by relationship to the 
    # target_collection for each member
    member_images.each do |solr_object|
      begin
        logger.info("Moving #{solr_object['id']} to DIL Collection")
        m = Multiresimage.find(solr_object['id'])
        if m.institutional_collection_id == target_collection.pid
          logger.warn("#{m.pid} skipped because it's already in the target collection")
        elsif m.institutional_collection_id != current_collection.pid
          logger.warn("#{m.pid} skipped because it's no longer in the current collection #{current_collection.pid}")
        else
          m.update_institutional_collection(target_collection)
        end
      rescue ActiveFedora::ObjectNotFoundError
        logger.error("#{solr_object['id']} not found, skipping")
      end
    end

    if get_member_images(current_collection).empty?
      # Delete the empty collection
      logger.info("Deleting #{current_collection.pid}...")
      current_collection.delete
    else
      logger.error("Skipping collection delete, images remain in #{current_collection.pid}")
      raise "Skipping collection delete, images remain in #{current_collection.pid}"
    end
  end

  private
  
  def get_member_images(collection)
    # Get the current_collection members
    member_images = []    
    Multiresimage.find_in_batches('is_governed_by_ssim'=>"info:fedora/#{collection.pid}") do |group|
      group.each { |solr_object|
        member_images << solr_object
      }
    end
    member_images
  end
end


