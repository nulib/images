class LockedObject < ActiveRecord::Base
  attr_accessible :pid, :type, :user_id, :created_at, :updated_at
  
  def self.obtain_lock(pid)
    #check for existing lock on collection
    if self.object_locked(pid)
      sleep 0.5
      nbr_lock_attempts = 0
      while object_locked and nbr_lock_attempts < 20 do
        nbr_lock_attempts = nbr_lock_attempts+1
        sleep 0.5
      end
      #unlock if nbr_lock_attemps is max
      #lock
      collection_lock = self.new(:pid=>pid)
      collection_lock.save!
    else
      collection_lock = self.new(:pid=>pid)
      collection_lock.save!
    end
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
