require "spec_helper"

describe "Catalog" do

  describe "a logged in user" do
    before do
      login FactoryGirl.find_or_create(:archivist)
    end
    it "should have links to upload images and groups " do
      visit catalog_index_path
      page.should have_selector("a[href='#{uploads_path}']", :text=>"Upload Images")
      page.should have_selector("a[href='#{groups_path}']", :text=>"Groups")
    end
  end

  describe "a user who is not logged in" do
    it "shouldn't have links to upload images " do
      visit catalog_index_path
      page.should_not have_selector("a[href='#{uploads_path}']", :text=>"Upload Images")
    end
  end

end
