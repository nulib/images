class User < ActiveRecord::Base
# Connects this user object to Hydra behaviors. 
 include Hydra::User
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  validates :uid, :presence => true

  # Setup accessible (or protected) attributes for your model
  attr_accessible :uid, :email, :password, :password_confirmation, :remember_me

  # eduPersonAffiliation
  serialize :affiliations, Array

  has_many :upload_files

  # Groups this user owns.  
  def owned_groups
    codes = Hydra::LDAP.groups_owned_by_user(uid)
    #puts "codes: #{codes}"
    Group.find_all_by_code(codes)
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    email
  end

  # Find an existing user by email or create one with a random password otherwise
  def self.find_for_ldap_oauth(access_token, signed_in_resource=nil)
    info = access_token[:info]
    if user = User.where(:email => info[:email]).first
      user
    else # Create a user with a stub password.
#puts "Info: #{info.inspect}"
      User.create!(:uid => info[:nickname], :email => info[:email], :password => Devise.friendly_token[0,20])
    end
  end

  # Copy data from session whenever a user is initialized before sign up
  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.ldap_data"] && session["devise.ldap_data"]["info"]
        user.email = data["email"]
      end
    end
  end

  # Groups that user is a member of
  def groups 
    codes = Hydra::LDAP.groups_for_user(uid)
    #puts "codes for #{uid} are #{codes}"
    res = Group.find_all_by_code(codes)
    #puts "res: #{res}"
    # add eduPersonAffiliation (e.g. student, faculty, staff) to groups that the user is a member of
    val = res + affiliations.map{ |code| Group.new(:code=>code) }
    val
  end

  def collections
    query="rightsMetadata_edit_access_machine_person_t:#{uid} AND has_model_s:info\\:fedora/afmodel\\:DILCollection" 
    ActiveFedora::SolrService.query(query, {:fl=>'id title_t'})
  end
end
