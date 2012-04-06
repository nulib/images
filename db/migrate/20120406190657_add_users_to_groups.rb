class AddUsersToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :users, :text 
  end
end
