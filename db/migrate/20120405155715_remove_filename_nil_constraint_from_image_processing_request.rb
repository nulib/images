class RemoveFilenameNilConstraintFromImageProcessingRequest < ActiveRecord::Migration
  def up
    change_column :image_processing_requests, :image_filename, :string, :null => true
  end

  def down
    change_column :image_processing_requests, :image_filename, :string, :null => false
  end
end
