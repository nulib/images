class CreateUploadFiles < ActiveRecord::Migration
  def change
    create_table :upload_files do |t|
      t.string :pid
      t.references :user

      t.timestamps
    end
    add_index :upload_files, :user_id
  end
end
