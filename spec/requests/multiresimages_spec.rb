require "spec_helper"

# NOTES:
#   See spec/models/ability_spec.rb for coverage describing who should have which permissions under various circumstances


# Descriptions of page contents

describe "When viewing images" do
  context "Given I have discover access" do
    before { login FactoryGirl.find_or_create(:nu_id_holder) }
    # NOTE: Tests for gated discovery (discover permissions in search results) are in spec/requests/gated_discovery_spec.rb
    #       These tests are only specifying what should appear on show/edit pages, not search results.
    context "When visiting show page for an image" do
      before { visit multiresimage_path('inu:dil-dept-access-image') }
      it "Then I should see the descriptive metadata" do
        page.should have_content("Agent")
        page.should have_content("Roberts, K. B ; Tomlinson, O. D. W ")
        page.should have_content("Title")
        page.should have_content("The Fabric of the Human Body (1992). Title page of H. Crooke's Microcosmographica")
        page.should have_content("Date")
        page.should have_content("1655")
        page.should have_content("Subject")
        page.should have_content("History of Medicine ; Anatomy, Artistic--Early works to 1800")
        page.should have_content("Location")
        page.should have_content("DIL:inu:dil-dept-access-image-work ; Voyager:259790")
        page.should have_content("Worktype")
        page.should have_content("Art & Science ; Medical Illustration ; Book arts ")
        page.should have_content("Identifier")
        page.should have_content("inu:dil-dept-access-image-work")
      end
      it "Then I should not see the image content & download links" do
        page.should_not have_selector("div#crop-tool")
        page.should_not have_link('thumbnail')
        page.should_not have_link('medium')
        page.should_not have_link('large')
      end
      it "Then I should see a message explaining that I do not have access" do
        page.should have_content("You do not have permission to view the content of this image.")
        page.should have_selector("li.current_owner", :text=>"joe_creator")
      end
      it "Then I should not see a link to the edit page" do
        page.should_not have_selector("a[href='#{edit_multiresimage_path('inu:dil-dept-access-image')}']")
      end
    end
  end

  context "Given I have read access" do
    before { login FactoryGirl.find_or_create(:nu_id_holder) }
    context "When visiting show page for an image" do
      before { visit multiresimage_path('inu:dil-nu-read-access-image') }
      it "Then I should see the descriptive metadata" do
        page.should have_content("Agent")
        page.should have_content("Roberts, K. B ; Tomlinson, O. D. W")
        page.should have_content("Title")
        page.should have_content("The Fabric of the Human Body (1992). Muscles and tendons of the dorsum of the foot. Tav. XVIII in A. Cattani, Osteografia e miografia..")
        page.should have_content("Date")
        page.should have_content("1780")
        page.should have_content("Subject")
        page.should have_content("History of Medicine ; Anatomy, Artistic--Early works to 1800")
        page.should have_content("Location")
        page.should have_content("Wellcome Institute Library. London ; DIL:inu:dil-nu-read-access-image-work ; Voyager:259835")
        page.should have_content("Material")
        page.should have_content("Engraving with etching")
        page.should have_content("Measurements")
        page.should have_content("33 x 22.2 cm.")
        page.should have_content("Worktype")
        page.should have_content("Art & Science ; Medical Illustration ; Book arts")
        page.should have_content("Identifier")
        page.should have_content("inu:dil-nu-read-access-image")
      end
      it "Then I should see the image content & download links" do
        page.should have_selector("div#crop-tool")
        page.should have_link('thumbnail')
        page.should have_link('medium')
        page.should have_link('large')
      end
      it "Then I should not see links to the technical metadata" do
        page.should_not have_link('EXIF Technical Metadata')
        page.should_not have_link('MIX Technical Metadata')
        page.should_not have_link('MIX Technical Metadata for JP2')
      end
      it "Then I should not see a link to the edit page" do
        page.should_not have_selector("a[href='#{edit_multiresimage_path('inu:dil-nu-read-access-image')}']")
      end
    end
  end

  context "Given I have edit access" do
    before { login FactoryGirl.find_or_create(:joe_creator) }
    context "When visiting show page for an image" do
      before { visit multiresimage_path('inu:dil-nu-read-access-image') }
      it "Then I should see a link to the edit page" do
        page.should have_selector("a[href='#{edit_multiresimage_path('inu:dil-nu-read-access-image')}']", :text=>"Edit")
      end
      it "Then I should see links to the technical metadata" do
        page.should have_link('EXIF Technical Metadata')
        page.should have_link('MIX Technical Metadata')
        page.should have_link('MIX Technical Metadata for JP2')
      end
    end
    context "When visiting edit page for an image" do
      before { visit edit_multiresimage_path('inu:dil-nu-read-access-image') }
      it "Then I should see a form for editing descriptive metadata"
      it "Then I should be able to edit the policy association" do
        page.should have_link "manage policies"
        select 'Policy', :with=>'Default Policy &mdash; Private to Owner'
        click_button 'Save changes'
        page.should have_content('Saved changes to inu:dil-nu-read-access-image')
      end
      it "Then I should see a link to the show/browse page" do
        page.should_not have_selector("a[href='#{multiresimage_path('inu:dil-nu-read-access-image')}']", :text=>"Browse")
      end
    end
  end

  context "Given I have admin access" do
    before { login FactoryGirl.find_or_create(:carol_curator) }
    context "When visiting edit page for an image" do
      it "Then I should see a link to the admin page" do
        pending "Admin permissions"
      end
    end
    context "When visiting admin page for an image" do
      it "Then I should see admin-only metadata" do
        pending "Admin permissions"
      end
    end
  end
end
