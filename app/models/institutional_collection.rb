# This model represents an Institutional Collection to which images belong. For example,
# a DIL image is part of the NUL Unit and DIL institutional collection. Both the unit and collection
# are stored in the descMetadata datastream. The multiresimage model has a belongs_to relationship
# with the InstitutionalCollection. This model acts like an Administrative Policy Object. Its permissions
# are inherited by its collection members. The most permissive permissions win out.

class InstitutionalCollection < ActiveFedora::Base

  include Hydra::AdminPolicyBehavior
  include Hydra::AccessControls::Permissions


  has_metadata 'descMetadata', type: ActiveFedora::QualifiedDublinCoreDatastream do |m|
    m.title :type=> :text, :index_as=>[:searchable]
  end

  has_attributes :title, :description, datastream: 'descMetadata', multiple: false
  has_attributes :license_title, datastream: 'rightsMetadata', at: [:license, :title], multiple: false
  has_attributes :license_description, datastream: 'rightsMetadata', at: [:license, :description], multiple: false
  has_attributes :license_url, datastream: 'rightsMetadata', at: [:license, :url], multiple: false


end
