require 'capybara/rspec'
require 'rails_helper'
require 'feature_utilities'


Capybara.default_driver = :selenium
Capybara.default_wait_time = 5

steps 'Images will create batches of multiresimages from valid vra and tifs', :js => true do
  before :all do
    @driver = :rack_test
    visit('http://localhost:3000/users/sign_in')
    within("#new_user") do
      fill_in 'username', :with => Rails.application.secrets["test_admin_id"]
      fill_in 'password', :with => Rails.application.secrets["test_admin_password"]
    end
    click_button('signIn')
  end

  it "admins can create records" do
    delay_jobs = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = false

    click_link("Batch Import")
    fill_in("job_number", :with =>  "valid_job")
    click_button("Create Image Records")
    sleep(10)

    fill_in("q", :with => "Hello")
    click_button("Search")

    expect(page).to have_content("Hello Titles")

    find('a', :text => "Hello Titles", match: :first).click
    page.accept_confirm "Are you sure you want to delete this image?" do
      click_link "Delete Image"
    end
    tif = Dir.glob('tmp/*.tif*').first

    FileUtils.mv(tif, "lib/assets/dropbox/batches/valid_job/#{File.basename(tif)}")
    File.rename("lib/assets/dropbox/batches/valid_job/#{File.basename(tif)}", "lib/assets/dropbox/batches/valid_job/great_vra.tiff")
    Delayed::Worker.delay_jobs = delay_jobs
  end
end
