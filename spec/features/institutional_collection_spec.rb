require 'capybara/rspec'
require 'rails_helper'


RSpec.feature "Institutional Collection", :type => :feature do
  before :all do
    @driver = Capybara.default_driver
    #visit "http://localhost:3000"
  end

  #setting a restricted multiresimage institutional_collection to a public collection makes it publicly viewable
  scenario 'being governed by a public collection makes a multiresimage publicly available' do
    #based on fixture data
    restricted_image = Multiresimage.find("inu:dil-f36a77f8-e2af-4139-b5e6-e0e9cf09ab63")
    public_collection = InstitutionalCollection.find("inu:dil-2bf7d015-76b1-4a7e-a198-4f0923cd4b92")
    default_registered_collection = InstitutionalCollection.first

    restricted_image.update_institutional_collection(public_collection)
    restricted_image.save!

    visit "http://localhost:3000/multiresimages/inu:dil-f36a77f8-e2af-4139-b5e6-e0e9cf09ab63"
    expect(page).to have_css '.blacklight-multiresimages-show'
    expect(page).to have_content 'By a waterfall'

    #return it to original state
    restricted_image.update_institutional_collection(default_registered_collection)
    restricted_image.save!
  end


  scenario 'being governed by the default registered collection makes a multiresimage unavailable to public' do

    #based on fixture data
    public_image = Multiresimage.find("inu:dil-af3c7e97-8fee-4a3d-8584-913fd3089c92")
    public_collection = public_image.institutional_collection
    puts "public col pid #{public_collection.pid}"
    default_registered_collection = InstitutionalCollection.first

    public_image.update_institutional_collection(default_registered_collection)
    public_image.save!

    visit "http://localhost:3000/multiresimages/inu:dil-af3c7e97-8fee-4a3d-8584-913fd3089c92"
    expect(page).not_to have_content '"--Pass the ammunition" : the Army needs more lumber'
    expect(page).to have_content "Sign in with a NetID"

    #return it to original state
    public_image.update_institutional_collection(public_collection)
    public_image.save!
    end
end
