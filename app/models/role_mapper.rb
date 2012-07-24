class RoleMapper
  
  # 
  # @param user_or_uid either the User object or user id
  # If you pass in a nil User object (ie. user isn't logged in), or a uid that doesn't exist, it will return an empty array
  def self.roles(user_or_uid)
    if user_or_uid.kind_of?(String)
      user = User.find_by_uid(user_or_uid)
    elsif user_or_uid.kind_of?(User) && !user_or_uid.uid.nil?  
      user = user_or_uid
    end
    return [] unless user 
    groups = user.groups.map{|r| r.code} << 'registered' unless user.new_record?
    return groups
  end


end
