class AddInstitutionalCollectionWorker
  include Sidekiq::Worker

  def perform(target_collection_id, pid_list)
    begin
      target_collection = InstitutionalCollection.find(target_collection_id)
      dil_collection = InstitutionalCollection.find("inu:dil-00-23655b1f-7029-4fb4-aa10-8ababe0ca63b")
    rescue ActiveFedora::ObjectNotFoundError => e
      Sidekiq::Logging.logger("Something went wrong with the collections in your batch")
      raise
    end

    pid_list.each do |pid|
      # begin
      #   m = Multiresimage.find(pid)
      #   m.update_institutional_collection(target_collection) unless m.institutional_collection_id == target_collection.pid
      # rescue
      #   Sidekiq::Logging.logger("The image #{m} didn't make it")
      # end
      AddImageToInstitutionalCollectionWorker.perform_async(pid, target_collection)
    end
  end
end