require "spec_helper"

describe "Edit permissions for a multiresimage" do

  describe "as a user with edit permissions" do
    before do
      login FactoryGirl.find_or_create(:staff)
      @fixture = Multiresimage.find('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
    end
    after(:all) do
      ActiveFedora::FixtureLoader.new(File.dirname(__FILE__) + '/../fixtures').reload('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
    end
    it "should be able to add and modify permissions for groups" do
      visit edit_multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
      page.should have_selector("fieldset.permissions")
      page.should_not have_selector("#multiresimage_permissions_group_test_group_1")
      fill_in("multiresimage_permissions_new_group_name", :with=>"test_group_1")
      select("View", :from=>"multiresimage_permissions_new_group_permission")
      click_on('Add Group')
      page.should have_selector(".msg.notice", :text=>"Updated permissions for #{@fixture.titleSet_display}.")
      page.should have_select("multiresimage_permissions_group_test_group_1", :selected => "View")
      select("Edit", :from=>"multiresimage_permissions_group_test_group_1")
      click_on('test_group_1_update_permission')
      page.should have_selector(".msg.notice", :text=>"Updated permissions for #{@fixture.titleSet_display}.")
      page.should have_select("multiresimage_permissions_group_test_group_1", :selected => "Edit")
    end
    
    it "should be able to add and modify permissions for individuals" do
      visit edit_multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
      page.should have_selector("fieldset.permissions")
      page.should_not have_selector("#multiresimage_permissions_user_test_user_1")
      fill_in("multiresimage_permissions_new_user_name", :with=>"test_user_1")
      select("View", :from=>"multiresimage_permissions_new_user_permission")
      click_on('Add Person')
      page.should have_selector(".msg.notice", :text=>"Updated permissions for #{@fixture.titleSet_display}.")
      page.should have_select("multiresimage_permissions_user_test_user_1", :selected => "View")
      select("Discover", :from=>"multiresimage_permissions_user_test_user_1")
      click_on('test_user_1_update_permission')
      page.should have_selector(".msg.notice", :text=>"Updated permissions for #{@fixture.titleSet_display}.")
      page.should have_select("multiresimage_permissions_user_test_user_1", :selected => "Discover")
    end
    
    it "should be able to remove permissions" do
      visit edit_multiresimage_path('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26')
      page.should have_selector("fieldset.permissions")
      page.should have_selector("#multiresimage_permissions_user_test_user_1")
      select("No Access", :from=>"multiresimage_permissions_user_test_user_1")
      click_on('test_user_1_update_permission')
      page.should have_selector(".msg.notice", :text=>"Updated permissions for #{@fixture.titleSet_display}.")
      page.should_not have_selector("#multiresimage_permissions_user_test_user_1")
    end
  end
end

