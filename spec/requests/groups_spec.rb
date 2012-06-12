require "spec_helper"

describe "Create a group" do

  describe "as a logged in user" do
    before do
      Hydra::LDAP.should_receive(:create_group) do |*args|
        Hydra::LDAP.should_receive(:groups_owned_by_user).and_return([args.first])
      end
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

