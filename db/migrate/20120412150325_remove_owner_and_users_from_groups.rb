class RemoveOwnerAndUsersFromGroups < ActiveRecord::Migration
  def up
    remove_column :groups, :users
    remove_column :groups, :owner_id
    
  end

  def down
    add_column :groups, :users, :text 
    add_column :groups, :owner_id, :integer 
  end
end
