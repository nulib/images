require 'spec_helper'

describe VRADatastream do
  describe "to_solr" do
    before do
      @vra_datastream = Multiresimage.find('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26').VRA
    end
    subject {@vra_datastream.to_solr}
    it "should have title_t" do
      subject["title_t"].should == ["Evanston Public Library. Exterior: facade"]
    end
    it "should have title_display" do
      subject["title_display"].should == "Evanston Public Library. Exterior: facade"
    end
  end

end
