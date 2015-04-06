require 'rails_helper'

describe VRADatastream do
  describe "valid vra" do
    it "ensures object type facet is correct" do
      xml_from_menu = File.read( "#{ Rails.root }/spec/fixtures/vra_image_sample.xml" )
      m = Multiresimage.create( from_menu: true, vra_xml: xml_from_menu )
      expect( m.VRA.to_solr["object_type_facet"] ).to eq ["Multiresimage"]
    end
  end
end