require 'capybara/rspec'
require 'rails_helper'
require 'rake'
require 'feature_utilities'

# README: Run the rake hydra:fixtures:refresh command besides the db:test:prepare commands in order to have
# images present. Also for now I just run it alone with the rspec spec/features/add_image_to_collection_spec.rb command.

# You'll also need to have firefox 24 installed to run the tests, and make sure rails is running in another tab.
# need a teardown that removes each image from collection after each test
# 12/19 - using fixture data like "Marche" for search term; new gem for maintaining session among specific tests
# you need a .env file with the credentials in it, in your root directory, also.


Capybara.default_driver = :selenium
Capybara.default_wait_time = 5

#Tests

steps 'Logged-in Users can use Images to view Collections',  :js => true do
  before :all do
    @driver = Capybara.default_driver
    visit('http://localhost:3000/users/sign_in')
    within("#new_user") do
      fill_in 'username', :with => Rails.application.secrets["test_non_admin_id"]
      fill_in 'password', :with => Rails.application.secrets["test_non_admin_password"]
    end
    click_button('signIn')
  end

  it "does not create facets from subject display data" do
    visit('http://localhost:3000/multiresimages/inu:dil-af3c7e97-8fee-4a3d-8584-913fd3089c92')

    #subject display fixture data - would be ideal to get this from fedora
    expect(page).to have_content("World War, 1939-1945--War work--United States--Posters ; War posters, American ; Defense work ")


    find('#logo a').click
    find_link('Subject').click
    find_link('more').click

    terms_not_in_facets = true

    next_link_exists = true

    while next_link_exists do
      begin
        find_link('Next').click
      rescue Capybara::ElementNotFound
        next_link_exists = false
      end
        all('a').each do |a|
          if a[:text].include?("War, 1939-1945--War work--United States--Posters ; War posters, American ; Defense work")
            terms_not_in_facets = false
          end
        end
    end

    expect(terms_not_in_facets).to be_truthy

  end

end

