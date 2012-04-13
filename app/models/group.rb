class Group < ActiveRecord::Base
  validates :name, :presence => true

  attr_accessor :users_text

  before_save :assign_code, :persist_to_ldap
  before_destroy :delete_from_ldap

  def assign_code
    if code.nil?
      self.code = UUID.new.generate
    end
  end

  def persist_to_ldap
    Dil::LDAP.create_group(code, name, owner_uid, @users)
  end

  def delete_from_ldap
    Dil::LDAP.delete_group(code)
  end

  def users=(u)
    @users = u
  end

  def users
    @users ||= Dil::LDAP.users_for_group(self.code)
  end

  def owner=(u)
    @owner = u
  end

  def owner_uid
    return @owner_uid if @owner_uid
    if @owner
      @owner_uid = @owner.uid
    elsif !new_record?
      @owner_uid = Dil::LDAP.owner_for_group(self.code)
    end
    @owner_uid
  end

  def owner
    @owner ||= User.find_by_uid(owner_uid)
  end


end
