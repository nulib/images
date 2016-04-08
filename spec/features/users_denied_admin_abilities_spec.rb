require 'capybara/rspec'
require 'rails_helper'
require 'rake'
require 'feature_utilities'

Capybara.default_driver = :selenium
Capybara.default_wait_time = 5


RSpec::Steps.steps 'Logged-in Users do not have admin abilities' do
  before :all do
    @driver = :rack_test
     visit('http://localhost:3000/users/sign_in')
     within("#new_user") do
       fill_in 'username', :with => Rails.application.secrets["test_non_admin_id"]
       fill_in 'password', :with => Rails.application.secrets["test_non_admin_password"]
     end
     click_button('signIn')
  end

  it "does not show the delete button" do
    visit('http://localhost:3000/multiresimages/inu:dil-af3c7e97-8fee-4a3d-8584-913fd3089c92')
    expect(page).to_not have_content("Delete Image")
  end

end
