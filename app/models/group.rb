class Group < ActiveRecord::Base
  belongs_to :owner, :class_name=>"User"

  validates :name, :presence => true

  serialize :users # TODO this should come from LDAP

  scope :system_groups, where(:owner_id => nil)
end
