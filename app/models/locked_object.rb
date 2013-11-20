class LockedObject < ActiveRecord::Base
  attr_accessible :pid, :action, :user_id, :created_at, :updated_at
  
  def self.obtain_lock(pid, action, user_id)
    #check for existing lock on collection
    nbr_lock_attempts = 0
    
    while self.object_locked(pid) and nbr_lock_attempts < DIL_CONFIG['max_nbr_lock_attempts'] do
      nbr_lock_attempts = nbr_lock_attempts + 1
      sleep DIL_CONFIG['record_lock_sleep_value']
    end
   
   #need to unlock if nbr_lock_attemps is max
    if nbr_lock_attempts == DIL_CONFIG['max_nbr_lock_attempts']
      raise Exception, "Could not obtain lock on record: #{pid}"
    else
      #lock
      collection_lock = self.new(:pid=>pid, :action=>action, :user_id=>user_id)
      collection_lock.save!
    end

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
