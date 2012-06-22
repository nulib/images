require "spec_helper"

# Descriptions of page contents

describe "when you have discover access"
  describe "viewing search result for an image" do
    it "should see the image in search results"
  end
  describe "visiting show page for an image" do
    it "should see the descriptive metadata"
    it "should not see the image content & download links"
  end
end

describe "when you have read access"
  describe "visiting show page for an image" do
    it "should see the descriptive metadata"
    it "should see the image content & download links"
    it "should not see a link to the edit page"
  end
end

describe "when you have edit access"
  describe "visiting show page for an image" do
    it "should see a link to the edit page"
  end
  describe "visiting edit page for an image" do
    it "should see technical metadata"
    it "should see a link to the show/browse page"
  end
end

describe "when you have admin access"
  describe "visiting edit page for an image" do
    it "should see a link to the admin page"
  end
  describe "visiting admin page for an image" do
    it "should see admin-only metadata"
  end
end

describe "View a multiresimage" do

  describe "as a logged in user" do
    before do
      login FactoryGirl.find_or_create(:nu_id_holder)
    end
    it "should display the object" do
      visit multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
      page.should have_selector("#sidebar a[href='#{catalog_index_path}']", :text=>'Search')
      page.should have_selector("a[href='#{edit_multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')}']", :text=>'Edit')
      click_on("Edit")
      page.should have_selector("#sidebar a[href='#{catalog_index_path}']", :text=>'Search')
    end

  end

  describe "as a staff member" do
    before do
      login FactoryGirl.find_or_create(:staff)
    end
    it "should display links to the technical metadata" do
      visit multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
      page.should have_link('EXIF Technical Metadata')
      page.should have_link('MIX Technical Metadata')
      page.should have_link('MIX Technical Metadata for JP2')
    end
    describe "GET /multiresimages/inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26/edit"
    it "should edit the object" do
      visit edit_multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
      page.should have_link "manage policies"
      select 'Policy', :with=>'Default Policy &mdash; Private to Owner'
      click_button 'Save changes'
      page.should have_content('Saved changes to inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
    end
  end

  describe "as a non-staff member" do
    before do
      login FactoryGirl.find_or_create(:student)
    end
    it "should not display links to the technical metadata" do
      visit multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
      page.should_not have_link('EXIF Technical Metadata')
      page.should_not have_link('MIX Technical Metadata')
      page.should_not have_link('MIX Technical Metadata for JP2')
    end
  end
end
