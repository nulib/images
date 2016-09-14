class RemoveInstitutionalCollectionImagesWorker
  include Sidekiq::Worker

  def perform(current_collection_pid, solr_object)
    # Change the :is_governed_by relationship to the target_collection for each member
    begin
      target_collection = InstitutionalCollection.find(DIL_CONFIG["institutional_collection"]["Digital Image Library"]["pid"]) # DIL COLLECTION      
      m = Multiresimage.find(solr_object['id'])
      raise "#{m.pid} skipped because it's already in the target collection" if m.institutional_collection_id == target_collection.pid
      raise "#{m.pid} skipped because it's no longer in the current collection #{current_collection.pid}" if m.institutional_collection_id != current_collection_pid
      m.update_institutional_collection(target_collection)
    rescue ActiveFedora::ObjectNotFoundError
      raise "#{solr_object['id']} not found, skipping"
    end
  end

  def on_success(status, options)
    logger.info("ALL DONE: Images all removed from: #{options['current_collection_pid']}")
  end

  def on_complete(status,options)
    logger.info("Complete with failures: #{status.failures}")
  end

  def self.remove_from_collection(current_collection_pid, member_images)
    batch = Sidekiq::Batch.new
    batch.on(:success, self, 'current_collection_pid' => current_collection_pid)
    batch.on(:complete, self, 'current_collection_pid' => current_collection_pid)
    batch.jobs do
      member_images.each do |solr_object|
        perform_async(current_collection_pid, solr_object)
      end
    end
  end
end


