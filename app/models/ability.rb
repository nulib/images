class Ability
  include CanCan::Ability
  include Hydra::Ability

  ## You can override this method if you are using a different AuthZ (such as LDAP)
  def user_groups(user, session)
#puts "Call to user_groups with #{user}: #{user.groups.inspect}"
#raise if user.nil?
    return @user_groups if @user_groups
    @user_groups = user.groups.map(&:code) + default_user_groups
    @user_groups << 'registered' unless user.new_record?
    @user_groups
  end

  def custom_permissions(user, session)
    ### Delegate Multiresimage permissions to the collection
    can :read, Multiresimage do |obj|
      test_read(user,session) || can_read_collection?(obj, user, session)
    end

    can [:edit, :destroy], Multiresimage do |obj|
      test_edit(user,session) || can_edit_collection?(obj, user, session)
    end
    can :destroy, ActiveFedora::Base do |obj|
      obj.rightsMetadata.individuals[user.email] == 'edit'
    end
  end

  private
  def can_edit_collection?(obj, user, session)
    pid = obj.collection_id
    return false unless pid
    @response, @permissions_solr_document = get_permissions_solr_response_for_doc_id(pid)
    test_edit(user, session)
  end
  def can_read_collection?(obj, user, session)
    pid = obj.collection_id
    return false unless pid
    @response, @permissions_solr_document = get_permissions_solr_response_for_doc_id(pid)
    test_read(user, session)
  end
end
