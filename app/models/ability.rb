class Ability
  include CanCan::Ability
  include Hydra::Ability

  ## You can override this method if you are using a different AuthZ (such as LDAP)
  def user_groups(user, session)
    return @user_groups if @user_groups
    @user_groups = user.groups.map(&:code) + default_user_groups
    @user_groups << 'registered' unless user.new_record?
    @user_groups
  end

  def custom_permissions(user, session)
    can :create, DILCollection unless user.new_record?

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
  end

  private
  def can_edit_collection?(obj, user, session)
    pid = obj.collection_id
    return false unless pid
    @permissions_solr_document = nil # force reload
    test_edit(pid, user, session)
  end
  def can_read_collection?(obj, user, session)
    pid = obj.collection_id
    return false unless pid
    @permissions_solr_document = nil # force reload
    test_read(pid, user, session)
  end
end
