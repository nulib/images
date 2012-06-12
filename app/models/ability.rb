class Ability
  include CanCan::Ability
  include Hydra::Ability

  ## This method overrides the default Hydra implementation to provide LDAP integration
  def user_groups(user, session)
    return @user_groups if @user_groups
    @user_groups = default_user_groups
    @user_groups += Hydra::LDAP.groups_for_user(user.uid) << 'registered' unless user.new_record?
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
      test_read(obj.pid, user,session) || can_read_collection?(obj, user, session)
    end


    can [:edit, :update, :destroy], Multiresimage do |obj|
      test_edit(obj.pid, user,session) || can_edit_collection?(obj, user, session)
    end
    can :destroy, ActiveFedora::Base do |obj|
      obj.rightsMetadata.individuals[user.email] == 'edit'
    end

    # Technical metadata should only be shown to staff
    # membership in staff is provided by LDAP as eduPersonAffiliation (rather than groupOfNames)
    can :show, :technical_metadata if user.affiliations.include?("staff")
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
