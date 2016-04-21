require 'capybara/rspec'
require 'rails_helper'
require 'rake'
require 'feature_utilities'

Capybara.default_driver = :selenium
Capybara.default_wait_time = 5

RSpec::Steps.steps 'Images returns proper error codes and pages' do
  it "responds to 404s with not_found_error", :error_handling => true do
    visit "/error"
  #  expect(page.status_code).to eq 404
    expect(page).to have_content("Page Not Found")
  end

  it "responds to 500s with internal_server_error", :error_handling => true do
    visit "/ouch"
  #  expect(page.status_code).to eq 500
    expect(page).to have_content("We're sorry, but the Images server is experiencing problems.")
  end
end
