class AddPidToImageProcessingRequest < ActiveRecord::Migration
  def change
    add_column :image_processing_requests, :pid, :string, {:null=>false, :default=>'migrated'}
  end
end
