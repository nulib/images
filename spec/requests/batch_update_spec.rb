# encoding: UTF-8

require "spec_helper"

describe "Select images to update" do

  describe "as a logged in user" do
    before do
      login FactoryGirl.find_or_create(:archivist)
    end
    it "should have a form" do
      fill_in("q", :with=>"Phillip")
      click_on("Submit")

      page.should have_selector("input.batch-all-button[type='submit'][value='Use all results']")

      page.should have_selector("input[type='submit'][class='batch_submit'][id='batch_submit_inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26']")
      # The blacklight javascript transforms the above element into this:
      #  input[type='checkbox'][class='toggle_folder'][id='toggle_folder_inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26']

      click_on "Use all results"
      page.should have_selector("form[action='#{batch_edits_path}']")

      select "Default Policy — Private to Owner", :from=>"Policy"

      click_on "Save changes"
      
      page.should have_content("Batch update complete")

      
    end
  end
end


