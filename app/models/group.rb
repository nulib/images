class Group < ActiveRecord::Base
  ## TODO delete owner and users from the database
#  belongs_to :owner, :class_name=>"User"

  validates :name, :presence => true

  scope :system_groups, where(:owner_id => nil)

  attr_accessor :users_text

  before_save :assign_code, :persist_to_ldap
  before_destroy :delete_from_ldap

  def assign_code
    if code.nil?
      self.code = UUID.new.generate
    end
  end

  def persist_to_ldap
    Dil::LDAP.create_group(code, owner.uid, @users)
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

  def owner
    @owner ||= Dil::LDAP.owner_for_group(self.code)
  end


end
