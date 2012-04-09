require "spec_helper"

describe "Create a group" do

  describe "as a logged in user" do
    before do
      login FactoryGirl.find_or_create(:archivist)
    end
    it "should have a form" do
      visit groups_path
      page.should have_selector("#sidebar a[href='#{catalog_index_path}']", :text=>'Search')
      click_on('Add a group')

      page.should have_selector("#sidebar a[href='#{catalog_index_path}']", :text=>'Search')
      fill_in("group_name", :with=>"My Group")
      fill_in("group_users_text", :with=>"fred,wilma barney")
      click_on('Create Group')
      page.should have_selector("li.group", :text=>'My Group')
      
    end
  end
end

