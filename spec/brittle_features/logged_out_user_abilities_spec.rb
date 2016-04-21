require 'capybara/rspec'
require 'rails_helper'
require 'rake'
require 'feature_utilities'

Capybara.default_driver = :selenium
Capybara.default_wait_time = 5

RSpec::Steps.steps "Logged out users can use Images for searching",  :js => true do
  before :all do
    @driver = :rack_test
  end

  it "lets you do a facets (narrowing) search" do
    visit('http://localhost:3000')
    find_link('Work Type').click
    find_link('Prints').click
    expect(page).to have_selector('.listing', count: 6)
  end

  it "lets you choose how many images you see in search results" do
    visit('http://localhost:3000/catalog?utf8=%E2%9C%93&q=*')
    click_button('Sort by Relevance')
    find('.dropdown-menu').visible?
  end

  it "lets you choose the sort method for search results" do
    visit('http://localhost:3000/catalog?utf8=%E2%9C%93&q=*')
    click_button('10 per page')
    find('.dropdown-menu').visible?
  end

  it "won't display 'add an image to a group' unless user is signed in" do
    visit("http://localhost:3000/multiresimages/inu:dil-c5275483-699b-46de-b7ac-d4e54112cb60")

    expect(page).to_not have_content("Add to Image Group")
  end
end

steps "Logged-out users can see metadata elements on a public image record page" do

  it "an image record contains a textref Element" do
    visit("http://localhost:3000/multiresimages/inu:dil-c5275483-699b-46de-b7ac-d4e54112cb60")

    expect(page).to have_content("Textref:")
  end
end
