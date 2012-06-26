module PermissionsHelper
  
  def permissions_users(obj)
    users_for_permtype(obj, :permissions)
  end
  
  def permissions_groups(obj)
    groups_for_permtype(obj, :permissions)
  end

  # @example
  #  groups_for_permtype(obj, :defaultPermissions)
  #  groups_for_permtype(obj, :permissions
  def groups_for_permtype(obj, perm_type) 
    sort_permissions(obj.send(perm_type).select {|p| p[:type] == "group"})    
  end
  
  def users_for_permtype(obj, perm_type) 
    sort_permissions(obj.send(perm_type).select {|p| p[:type] == "user"})    
  end

  def sort_permissions(permissions)
    permissions.sort_by! {|p| p[:name] }
  end
  
end
