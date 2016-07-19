require 'capybara/rspec'
require 'rails_helper'


RSpec.feature "Institutional Collection", :type => :feature do
  before :all do
    @driver = Capybara.default_driver
  end

  #setting a restricted multiresimage institutional_collection to a public collection makes it publicly viewable
  scenario 'collections successfully govern multiresimage permissions' do

    #based on fixture data
    restricted_image = Multiresimage.find("inu:dil-f36a77f8-e2af-4139-b5e6-e0e9cf09ab63")
    public_collection = InstitutionalCollection.find("inu:dil-2bf7d015-76b1-4a7e-a198-4f0923cd4b92")


    restricted_image.update_institutional_collection(public_collection)
    restricted_image.save!

    # visit('http://localhost:3000/users/sign_in')
    # within("#new_user") do
    #   fill_in 'username', :with => Rails.application.secrets["test_non_admin_id"]
    #   fill_in 'password', :with => Rails.application.secrets["test_non_admin_password"]
    # end
    # click_button('signIn')


    visit "http://localhost:3000/multiresimages/inu:dil-f36a77f8-e2af-4139-b5e6-e0e9cf09ab63"
    expect(page).to have_css '.blacklight-multiresimages-show'
    expect(page.html).to include('<h1>"By a waterfall"</h1>')
  end
end
