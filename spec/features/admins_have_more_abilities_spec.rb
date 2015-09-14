require 'capybara/rspec'
require 'rails_helper'
require 'rake'
require 'feature_utilities'

Capybara.default_driver = :selenium
Capybara.default_wait_time = 5

steps 'admins have abilities', :js => true  do
  before :all do
    @driver = :rack_test
    visit('http://localhost:3000/users/sign_in')
    within("#new_user") do
      fill_in 'username', :with => Rails.application.secrets["test_admin_id"]
      fill_in 'password', :with => Rails.application.secrets["test_admin_password"]
    end
    click_button('signIn')
  end

  it "shows admins the delete button" do
    visit('http://localhost:3000/multiresimages/inu:dil-af3c7e97-8fee-4a3d-8584-913fd3089c92')

    expect(page).to have_content("Delete Image")
  end

 it "shows admins the delete button even if the svg_datasteam is empty" do
    page.accept_confirm "ImageServer.initialize: Unable to fetch /multiresimages/svg/inu:dil-142f8a4d-0c42-4da5-b17d-662db3283d74. Check that everything is served from the same host." do
        visit('http://localhost:3000/multiresimages/inu:dil-142f8a4d-0c42-4da5-b17d-662db3283d74')
    end

    expect(page).to have_content("Delete Image")
  end

end