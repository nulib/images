class User < ActiveRecord::Base
# Connects this user object to Hydra behaviors. 
 include Hydra::User
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    email
  end

  # Find an existing user by email or create one with a random password otherwise
  def self.find_for_ldap_oauth(access_token, signed_in_resource=nil)
    data = access_token[:info]
    if user = User.where(:email => data[:email]).first
      user
    else # Create a user with a stub password.
      User.create!(:email => data[:email], :password => Devise.friendly_token[0,20])
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
end
