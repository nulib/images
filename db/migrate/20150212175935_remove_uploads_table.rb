class RemoveUploadsTable < ActiveRecord::Migration
  def change
    drop_table :upload_files
  end
end
