require "spec_helper"

describe "Uploading files" do

  describe "as a logged in user" do
    before do
      login FactoryGirl.find_or_create(:archivist)
    end
    it "should have upload form and a list of files" do
      visit uploads_path
      page.should have_selector("form#fileupload")
      page.should have_selector("table > tbody.files")
    end
  end

  describe "as a user who is not logged in" do
    it "should redirect to sign in" do
      get uploads_path
      response.should redirect_to(new_user_session_path)
    end
  end

end

