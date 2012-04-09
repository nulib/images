class Group < ActiveRecord::Base
  belongs_to :owner, :class_name=>"User"

  validates :name, :presence => true

  serialize :users, Array # TODO this should come from LDAP

  scope :system_groups, where(:owner_id => nil)

  attr_accessor :users_text

  before_save :assign_code

  def assign_code
    if code.nil?
      self.code = UUID.new.generate
    end
  end


  def internal_uri
    "ldap://northwestern/groups/#{code}"
  end
end
