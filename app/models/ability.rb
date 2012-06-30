class Ability
  include CanCan::Ability
  include Hydra::Ability
  include PolicyAwareAbility

  ## This method overrides the default Hydra implementation to provide LDAP integration
  def user_groups(user, session)
    return @user_groups if @user_groups
    @user_groups = default_user_groups
    @user_groups += RoleMapper.roles(user)
    @user_groups
  end

  def custom_permissions(user, session)
    can :create, DILCollection unless user.new_record?
    can :update, DILCollection do |obj|
      test_edit(obj.pid, user,session)
    end

    can :edit, Group do |obj|
      obj.owner_uid == user.uid
    end

    ### Delegate Multiresimage permissions to the collection
    can :read, Multiresimage do |obj|
      test_read(obj.pid, user,session)
    end


    can [:edit, :update, :destroy, :view_technical_metadata], Multiresimage do |obj|
      test_edit(obj.pid, user,session)
    end
    can :destroy, ActiveFedora::Base do |obj|
      #TODO this may not be necessary.  Also it's ignoring groups.
      obj.rightsMetadata.individuals[user.email] == 'edit'
    end

    can :create, AdminPolicy
    can :update, AdminPolicy do |obj|
      test_edit(obj.pid, user,session)
    end

  end

  # Extends Hydra::Ability.test_edit to try policy controls if object-level controls deny access
  def test_edit(pid, user, session)
    result = super
    if result 
      return result
    else
      return test_edit_from_policy(pid, user, session)
    end
  end
  
  # Extends Hydra::Ability.test_read to try policy controls if object-level controls deny access
  def test_read(pid, user, session)
    result = super
    if result 
      return result
    else
      return test_read_from_policy(pid, user, session)
    end
  end
  

  
  private
  def can_edit_collection?(obj, user, session)
    pids = obj.collection_ids
    return false unless pids.present?
    @permissions_solr_document = nil # force reload
    ## TODO optimize - write a single solr query to check for permission on any of the pids
    pids.any? { |pid| test_edit(pid, user, session) }
  end
  def can_read_collection?(obj, user, session)
    pids = obj.collection_ids
    return false unless pids.present?
    @permissions_solr_document = nil # force reload
    ## TODO optimize - write a single solr query to check for permission on any of the pids
    pids.any? {|pid| test_read(pid, user, session)}
  end
end
