class GeneratePowerpointWorker
include Sidekiq::Worker

  def perform(collection_pid)
    DILCollection.find(collection_pid).generate_powerpoint
  end
end
