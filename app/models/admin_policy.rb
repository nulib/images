class AdminPolicy < ActiveFedora::Base

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "defaultRights", :type => Hydra::Datastream::RightsMetadata 

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  has_metadata :name =>'descMetadata', :type => ActiveFedora::QualifiedDublinCoreDatastream do |ds|
    ds.field :license_url
  end

  delegate_to :descMetadata, [:title, :description], :unique=>true
  delegate :license_title, :to=>'rightsMetadata', :at=>[:license, :title], :unique=>true
  delegate :license_description, :to=>'rightsMetadata', :at=>[:license, :description], :unique=>true
  delegate :license_url, :to=>'rightsMetadata', :at=>[:license, :url], :unique=>true

  # easy access to edit_groups, etc
  include Hydra::ModelMixins::RightsMetadata 


end
