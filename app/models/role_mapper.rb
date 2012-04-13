class RoleMapper
  def self.roles(uid)
    u = User.find_by_uid(uid)
    return [] unless u
    u.groups.map{|r| r.code}
  end


end
