class CreateLockedObjects < ActiveRecord::Migration
  def up
    create_table :locked_objects do |t|
     t.string :pid, :primary=>true
     t.string :type
     t.string :user_id
     t.timestamps
    end
  end

  def down
    drop_table :locked_objects
  end
end
