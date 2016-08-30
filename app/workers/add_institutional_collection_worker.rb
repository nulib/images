class AddInstitutionalCollectionWorker
  include Sidekiq::Worker

  def perform(target_collection_id, pid_list)
    begin
      target_collection = InstitutionalCollection.find(target_collection_id)
      dil_collection = InstitutionalCollection.find("inu:dil-00-23655b1f-7029-4fb4-aa10-8ababe0ca63b")
    rescue ActiveFedora::ObjectNotFoundError
      logger.error("Something went wrong with one of the collections in your batch")
      raise "Something went wrong with one of the collections in your batch"
    end

    pid_list.each do |pid|
      begin
        m = Multiresimage.find(pid)
        if m.institutional_collection_id == target_collection.pid
          logger.info("#{m.pid} skipped because it is already governed by #{target_collection.pid}")
        elsif m.institutional_collection_id != dil_collection.pid
          logger.error("#{m.pid} skipped because it is no longer in the DIL Collection")  
        else
          m.update_institutional_collection(target_collection)
          logger.info("#{m.pid} added to #{target_collection.pid}")
        end
      rescue
        logger.error("The image #{pid} didn't make it for an unknown reason")
      end
    end
  end
end