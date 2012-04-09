class AddCodeToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :code, :string
    #Work around glitch in SqlLite see: http://stackoverflow.com/a/6710280/162852
    change_column :groups, :code, :string, :null => false
  end
end
