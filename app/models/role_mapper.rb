class RoleMapper
  def self.roles(email)
    u = User.find_by_email(email)
    return [] unless u
    u.groups.map{|r| r.id}
  end


end
