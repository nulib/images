class RemoveImageProcessingRequests < ActiveRecord::Migration
  def change
    drop_table :image_processing_requests
  end
end
