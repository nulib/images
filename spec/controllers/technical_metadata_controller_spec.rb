require 'spec_helper'

describe TechnicalMetadataController do

  describe "routes" do
    it "should have technical_metadata_path" do
      technical_metadata_path(:id=>'test:123', :type=>'ARCHV-EXIF', :format=>'xml').should == '/technical_metadata/test:123/ARCHV-EXIF.xml'
    end
  end

  describe "#show technical metadata datastream for a multiresimage" do
    describe "when logged in as a member of staff" do
      before do
        @user = FactoryGirl.find_or_create(:staff)
        @img = Multiresimage.new
        @img.ARCHV_EXIF.content = <<-eof
          <exif><raw>---- ExifTool ----ExifTool Version Number   : 7.39---- File</raw></exif> 
        eof
        @img.edit_groups = ['staff']
        @img.save
        Hydra::LDAP.stub(:groups_for_user).with(@user.uid).and_return([])
        sign_in @user
      end
      it "should be successful" do
        get :show, {:id=>@img.pid, :type=>'ARCHV-EXIF', :format=>'xml'}
        response.should be_successful
        response.body.should have_xpath("//exif")
      end
    end

    describe "when logged in as a non-staff member" do
      before do
        @user = FactoryGirl.find_or_create(:student)
        Hydra::LDAP.stub(:groups_for_user).with(@user.uid).and_return([])
        sign_in @user
      end
      it "should fail" do
        get :show, {:id=>'inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26', :type=>'ARCHV-EXIF', :format=>'xml'}
        response.should redirect_to(root_path)
        flash[:alert].should == 'You are not authorized to access this page.'
      end
    end

    describe "when not logged in" do
      it "should fail" do
        get :show, {:id=>'inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26', :type=>'ARCHV-EXIF', :format=>'xml'}
        response.should redirect_to(root_path)
        flash[:alert].should == 'You are not authorized to access this page.'
      end
    end
  end
end
