# This model represents an Institutional Collection to which images belong. For example,
# a DIL image is part of the NUL Unit and DIL institutional collection. Both the unit and collection
# are stored in the descMetadata datastream. The multiresimage model has a belongs_to relationship
# with the InstitutionalCollection. This model acts like an Administrative Policy Object. Its permissions
# are inherited by its collection members. The most permissive permissions win out.

class InstitutionalCollection < ActiveFedora::Base

  include Hydra::AdminPolicyBehavior
  include Hydra::AccessControls::Permissions
  include Hydra::ModelMethods

  has_many :multiresimages, :class_name=> "Multiresimage", :property=> :has_collection_member
  has_many :multiresimages, :class_name=> "Multiresimage", :property=> :has_representative_member

  has_metadata 'descMetadata', type: ActiveFedora::QualifiedDublinCoreDatastream do |m|
    m.title :type=> :text, :index_as=>[:searchable]
  end

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  #has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  has_metadata :name => "properties", :type => ActiveFedora::SimpleDatastream do |m|
        # title_part and unit_part of the pieces of the (existing) Institional Collection title
        # ex: Unit|Title
        # redundant to store them but not sure we want to mess with the existing title setup...
        m.field "title_part", :string
        m.field "unit_part"
        m.field "rights_description", :string
  end

  has_attributes :title_part, :unit_part, :rights_description, datastream: 'properties', multiple: false
  has_attributes :title, :description, datastream: 'descMetadata', multiple: false
  has_attributes :license_title, datastream: 'rightsMetadata', at: [:license, :title], multiple: false
  has_attributes :license_description, datastream: 'rightsMetadata', at: [:license, :description], multiple: false
  has_attributes :license_url, datastream: 'rightsMetadata', at: [:license, :url], multiple: false


  def make_public
    #this refers to the rights in the defaultRights datastream, (the rights that are inhertied by images)
    self.default_permissions=[{:type=>"group", :access=>"read", :name=>"public"}]
  end

  def make_private
    #this refers to the rights in the defaultRights, (the ones inherited by images in collection)
    self.default_permissions=[{:type=>"group", :access=>"read", :name=>"registered"}]
  end

  def collection_title_formatter
    if title.nil? or title==""
      title
    else
      title.split("|")[1]
    end
  end

  def collection_unit_formatter
   title.split("|")[0]
  end

  def set_representative_image(image)
    unless self.relationships(:has_representative_member).empty?
      self.remove_relationship(:has_representative_member, self.relationships(:has_representative_member).first)
    end
    self.add_relationship(:has_representative_member, image)
  end

  def representative_image_pid
    unless self.relationships(:has_representative_member).empty?
      return self.relationships(:has_representative_member).first.gsub(/info:fedora\//, '')
    end
  end

end
