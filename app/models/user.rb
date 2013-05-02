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

  def settable_policies
    AdminPolicy.readable_by_user(self)
  end

  # Find an existing user by email or create one with a random password otherwise
  def self.find_for_ldap_oauth(access_token, signed_in_resource=nil)
    info = access_token[:info]
    if user = User.where(:email => info[:email].downcase).first
      user
    else # Create a user with a stub password.
#puts "Info: #{info.inspect}"
      User.create!(:uid => info[:nickname], :email => info[:email].downcase, :password => Devise.friendly_token[0,20])
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
    return @groups if @groups
    return [] if uid.nil?
    if uid == 'ega505'
      codes = ["superuser"]
    else
     codes = ["student"]
     #codes = Hydra::LDAP.groups_for_user(uid)
    end
    #puts "codes for #{uid} are #{codes}"
    res = Group.find_all_by_code(codes)
    #puts "res: #{res}"
    # add eduPersonAffiliation (e.g. student, faculty, staff) to groups that the user is a member of
    @groups = res + affiliations.map{ |code| Group.new(:code=>code) }
  end

  def get_uploads_collection
    query="rightsMetadata_edit_access_machine_person_tesim:#{uid} AND title_ssim:\"#{DIL_CONFIG['dil_uploads_collection']}\" AND active_fedora_model_s:DILCollection" 
    ActiveFedora::SolrService.query(query, {:fl=>'id title_tesim'})
  end
  
   def get_details_collection
    query="rightsMetadata_edit_access_machine_person_tesim:#{uid} AND title_ssim:\"#{DIL_CONFIG['dil_details_collection']}\" AND active_fedora_model_s:DILCollection" 
    ActiveFedora::SolrService.query(query, {:fl=>'id title_tesim'})
  end
  
  def collections
    query="rightsMetadata_edit_access_machine_person_tesim:#{uid} AND NOT title_ssim:\"#{DIL_CONFIG['dil_uploads_collection']}\" AND NOT title_ssim:\"#{DIL_CONFIG['dil_details_collection']}\" AND active_fedora_model_s:DILCollection" 
    ActiveFedora::SolrService.query(query, {:fl=>'id title_tesim', :rows=>'1000'})
  end

  def top_level_collections
    query="rightsMetadata_edit_access_machine_person_tesim:#{uid} AND NOT title_ssim:\"#{DIL_CONFIG['dil_uploads_collection']}\" AND NOT title_ssim:\"#{DIL_CONFIG['dil_details_collection']}\" AND active_fedora_model_s:DILCollection AND is_top_level_collection_ssim:true" 
    ActiveFedora::SolrService.query(query, {:fl=>'id title_tesim has_subcollection_ssim has_image_ssim', :rows=>'1000', :sort=>'system_create_dtsi desc'})
  end

  def self.admin_groups
     @admin_groups ||= YAML.load_file("config/admin_groups.yml")[Rails.env]
  end

  def admin?
    (User.admin_groups & groups.map(&:code)).length > 0
  end
end
