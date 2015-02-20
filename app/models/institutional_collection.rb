# This model represents an Institutional Collection to which images belong. For example,
# a DIL image is part of the NUL Unit and DIL institutional collection. Both the unit and collection
# are stored in the descMetadata datastream. The multiresimage model has a belongs_to relationship
# with the InstitutionalCollection. This model acts like an Administrative Policy Object. Its permissions
# are inherited by its collection members. The most permissive permissions win out.

class InstitutionalCollection < Hydra::AdminPolicy

  include Hydra::ModelMethods
  include Hydra::AccessControls::Permissions

  has_many :multiresimages, :class_name=> "Multiresimage", :property=> :has_collection_member

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "defaultRights", :type => Hydra::Datastream::InheritableRightsMetadata

  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  def to_solr(solr_doc=Hash.new)
    solr_doc = super(solr_doc)
    solr_doc
  end


end