class CreateImageProcessingRequests < ActiveRecord::Migration
  def self.up
    create_table :image_processing_requests do |t|
      t.string "image_pid", :limit =>50, :null=>true
      t.string "image_filename", :limit =>50, :null=>false
      t.string "email", :default => "", :null=>false
      t.string "status", :limit=>25, :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :image_processing_requests
  end
end

