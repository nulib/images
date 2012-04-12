class AddAffiliationsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :affiliations, :text

  end
end
