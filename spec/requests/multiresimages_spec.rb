require "spec_helper"

describe "View a multiresimage" do

  describe "as a logged in user" do
    before do
      login FactoryGirl.find_or_create(:archivist)
    end
    it "should display the object" do
      visit multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
      page.should have_selector("#sidebar a[href='#{catalog_index_path}']", :text=>'Search')
      page.should have_selector("a[href='#{edit_multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')}']", :text=>'Edit')
      click_on("Edit")
    end
  end
end


