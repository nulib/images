module PermissionsHelper
  
  def permissions_users(obj)
    users_for_field(obj, :permissions)
  end
  
  def permissions_groups(obj)
    groups_for_field(obj, :permissions)
  end
  
  def editors(obj)
    permissions_users(obj).select { |p| p[:access] == "edit" }
  end

  # @example
  #  groups_for_field(obj, :defaultPermissions)
  #  groups_for_field(obj, :permissions, ['read', 'edit'])
  def groups_for_field(obj, field, access = ['discover', 'read', 'edit']) 
    perms(obj, field, :group, access)
  end
  
  def users_for_field(obj, field, access = ['discover', 'read', 'edit']) 
    perms(obj, field, :user, access)
  end

  # @example
  #  perms(obj, :defaultPermissions, :user, :edit)
  #  perms(obj, :permissions, :group, [:view, :edit])
  def perms(obj, field, obj_type, access) 
    access = Array(access)
    sort_permissions(obj.send(field).select {|p| p[:type] == obj_type.to_s && access.map(&:to_s).include?(p[:access])})    

  end

  def sort_permissions(permissions)
    permissions.sort_by! {|p| p[:name] }
  end

end
