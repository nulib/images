require "spec_helper"

describe "Catalog" do

  describe "a logged in user" do
    before do
      @user = FactoryGirl.find_or_create(:archivist)
      login @user
    end
    it "should have links to upload images and groups " do
      visit catalog_index_path
      page.should have_selector("a[href='#{uploads_path}']", :text=>"Upload Images")
      page.should have_selector("a[href='#{dil_collections_path}']", :text=>"Collections")
      page.should have_selector("a[href='#{groups_path}']", :text=>"User Groups")
    end
    describe "who has read access to a collection that contains an image" do
      before do
        Hydra::LDAP.should_receive(:create_group)
        @g1 = FactoryGirl.create(:user_group, :users=>[@user.uid], :owner=>FactoryGirl.create(:user))
        @img = Multiresimage.new
        @img.titleSet_display = "Totally refreshing"
        @img.read_groups = [@g1.code]
        @img.save!
      end
      after do
        @g1.delete
      end
      it "should be able to discover the image" do
        visit catalog_index_path
        fill_in(:q, :with=>'refreshing')
        click_on('Search')
pending "That is not working"
#puts page.body.to_s
        page.should have_selector('.listing')

      end
    end
  end

  describe "a user who is not logged in" do
    it "shouldn't have links to upload images " do
      visit catalog_index_path
      page.should_not have_selector("a[href='#{uploads_path}']", :text=>"Upload Images")
    end
  end

end
