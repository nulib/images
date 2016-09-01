class AddInstitutionalCollectionWorker
  include Sidekiq::Worker

  def perform(pid, target_collection_id)
    target_collection = InstitutionalCollection.find(target_collection_id)
    dil_collection = InstitutionalCollection.find("inu:dil-00-23655b1f-7029-4fb4-aa10-8ababe0ca63b")

    logger.info("#{pid} is being processed.....")
    m = Multiresimage.find(pid)
    if m.institutional_collection_id == target_collection.pid
      logger.info("#{m.pid} skipped because it is already governed by #{target_collection.pid}")
      raise "#{m.pid} skipped because it is already governed by #{target_collection.pid}"
    elsif m.institutional_collection_id != dil_collection.pid
      logger.error("#{m.pid} skipped because it is no longer in the DIL Collection")
      raise "#{m.pid} skipped because it is no longer in DIL"
    else
      m.update_institutional_collection(target_collection)
      logger.info("#{m.pid} added to #{target_collection.pid}")
    end
  end

  def on_success(status, options)
    logger.info("ALL DONE: Images all moved into: #{options['collection_id']}")
  end

  def on_complete(status,options)
    logger.info("Complete with failures: #{status.failures}")
  end

  def self.add_to_collection(target_collection_id, pid_list)
    batch = Sidekiq::Batch.new
    batch.on(:success, self, 'collection_id' => target_collection_id)
    batch.on(:complete, self, 'collection_id' => target_collection_id)
    batch.jobs do
      pid_list.each do |pid|
        perform_async(pid, target_collection_id)
      end
    end
  end
end