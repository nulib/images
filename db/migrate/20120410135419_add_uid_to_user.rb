class AddUidToUser < ActiveRecord::Migration
  def change
    add_column :users, :uid, :string
    #Work around glitch in SqlLite see: http://stackoverflow.com/a/6710280/162852
    change_column :users, :uid, :string, :null => false
    add_index :users, :uid, :unique => true
  end
end
