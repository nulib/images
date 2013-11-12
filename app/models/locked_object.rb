class LockedObject < ActiveRecord::Base
  attr_accessible :pid, :action, :user_id, :created_at, :updated_at
  
  def self.obtain_lock(pid, action, user_id)
    #check for existing lock on collection
    while self.object_locked(pid) and nbr_lock_attempts < 20 do
      nbr_lock_attempts = nbr_lock_attempts+1
      sleep 0.5
    end
    #need to unlock if nbr_lock_attemps is max
    #lock
    collection_lock = self.new(:pid=>pid, :action=>action, :user_id=>user_id)
    collection_lock.save!
  end
  
  def self.release_lock(pid)
    self.delete_all("pid = '#{pid}'")
  end
  
private 
  def self.object_locked(pid)
    object_locked = false
    if self.exists?(:pid=>pid)
      object_locked = true
    end
    return object_locked
  end
  
end
