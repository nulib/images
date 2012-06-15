require 'spec_helper'

describe VRADatastream do
  describe "to_solr" do
    before :all do
      @vra_datastream = Multiresimage.new.VRA
      @vra_datastream.titleSet_display = "Evanston Public Library. Exterior: facade"
    end
    subject {@vra_datastream.to_solr}
    it "should not have title_t" do
      subject["title_t"].should == [""]
    end
    it "should have title_display_t" do
      subject["title_display_t"].should == ["Evanston Public Library. Exterior: facade"]
    end
    it "should have title_display" do
      subject["title_display"].should == ["Evanston Public Library. Exterior: facade"]
    end
  end

end
