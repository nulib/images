#!/usr/bin/evn ruby

# BE CAREFUL: If you want to run this, make sure the configs are set and un-comment the collection.save

# There is now a way to store the owner of a collection when the collection is created, but there
# are a bunch of collections that were already created without an owner. They were, however, added to the
# list of users who can edit the collection. The issue is that a bunch of admin users are also in that
# list. We need to figure out who the owner is and set that collection's owner.
# From the app's root level: rails runner -e environment lib/update_collection_owner.rb 


error_file = File.new('path_to_file', 'w')
log_file = File.new('path_to_file', 'w')
begin
  DILCollection.find_each {|collection|

    #if collection doesn't have owner yet
    if !collection.owner.present?
      log_file.write("#{collection.pid}: does not have owner\n")
    
      # See which user with edit is not in the admin staff config. That's the user who created the collection.
      owner = collection.edit_users - DIL_CONFIG["admin_staff"]
      
      # If the collection was indeed created by a faculty member (and not an admin staff person), assign the owner
      if owner.present? and owner.size == 1
        collection.owner = owner[0].to_s
        log_file.write("#{collection.pid}: owner:#{owner}\n")
        collection.save
        log_file.write("#{collection.pid}: saved successfully")
      else
        log_file.write("#{collection.pid}: #{owner.size} Could not assign owner\n")
      end
      
    else
      log_file.write("#{collection.pid}: has owner\n")
    end
  }
  
rescue Exception=>e
  error_file.write("Exception:#{e.message}\n")
ensure
  log_file.close
  error_file.close
end
  

