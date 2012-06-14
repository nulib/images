require "spec_helper"

describe "Select images to update" do

  describe "as a logged in user" do
    before do
      login FactoryGirl.find_or_create(:archivist)
    end
    it "should have a form" do
      pending
      fill_in("q", :with=>"Phillip")
      click_on("Submit")

      page.should have_selector("input[type='checkbox'][id='all']")
      page.should have_selector("input[type='submit'][class='folder_submit'][id='folder_submit_inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26']")
      # The blacklight javascript transforms the above element into this:
      #  input[type='checkbox'][class='toggle_folder'][id='toggle_folder_inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26']

      page.should have_selector("form.button_to input[type=submit][value='Edit Batch']")
      
    end
  end
end


