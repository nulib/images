class Ability
  include CanCan::Ability
  include Hydra::Ability

  def custom_permissions
    can :delete, ActiveFedora::Base do |obj|
      obj.rightsMetadata.individuals[@user.email] == 'edit'
    end

  end
end
