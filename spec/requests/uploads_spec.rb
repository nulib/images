require "spec_helper"

describe "Uploading files" do

  describe "as a logged in user" do
    before do
      login FactoryGirl.find_or_create(:archivist)
    end
    it "should have upload form and a list of files" do
      visit uploads_path
      page.should have_selector("form#fileupload[action='#{uploads_create_path}']")
      page.should have_selector("table > tbody.files")

      page.should have_selector("#sidebar a[href='#{catalog_index_path}']", :text=>'Search')

      attach_file('files[]', Rails.root.join("spec/fixtures/images/The_Tilled_Field.jpg"))
      click_on('Start upload')
      # Can't get this to work. even with :js =>true
      #wait_until{ page.has_selector?('tbody.files tr .name')}    
    end
  end

  describe "as a user who is not logged in" do
    it "should redirect to sign in" do
      get uploads_path
      response.should redirect_to(new_user_session_path)
    end
  end

end

