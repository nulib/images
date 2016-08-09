require 'capybara/rspec'
require 'rails_helper'


RSpec.feature "Image Viewing", :type => :feature, :js => true do
  before :all do
    @driver = Capybara.default_driver
    visit('http://localhost:3331/users/sign_in')
    within("#new_user") do
      fill_in 'username', :with => Rails.application.secrets["test_non_admin_id"]
      fill_in 'password', :with => Rails.application.secrets["test_non_admin_password"]
    end
    click_button('signIn')
  end

  scenario 'the multiresimage info.json is in the OSD-generated html' do
    visit "http://localhost:3331/multiresimages/inu:dil-af3c7e97-8fee-4a3d-8584-913fd3089c92"
    expect(page).to have_css 'div.openseadragon-container'
    expect(page.html).to include('<source src="/image-service/inu-dil-af3c7e97-8fee-4a3d-8584-913fd3089c92/info.json" media="openseadragon" />')
  end
end
