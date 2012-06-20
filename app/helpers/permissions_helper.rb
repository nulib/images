module PermissionsHelper
  
  def permissions_users(obj)
    sort_permissions(obj.permissions.select {|p| p[:type] == "user"})
  end
  
  def permissions_groups(obj)
    sort_permissions(obj.permissions.select {|p| p[:type] == "group"})    
  end
  
  def sort_permissions(permissions)
    permissions.sort_by! {|p| p[:name] }
  end
  
  
  def hashify_permissions(permissions)
    perms_hash = {}
    permissions.each do |p|
      perms_hash[p[:name]] = p[:access]
    end
    return perms_hash
  end
end