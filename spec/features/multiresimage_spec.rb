require 'capybara/rspec'
require 'rails_helper'

RSpec.feature "Image Viewing", :type => :feature, :js => true do
  scenario 'the multiresimage info.json is in the OSD-generated html' do
    visit "http://localhost:3331/multiresimages/inu:dil-af3c7e97-8fee-4a3d-8584-913fd3089c92"
    expect(page).to have_css 'div.openseadragon-container'
    expect(page.html).to include('<source src="/image-service/inu-dil-af3c7e97-8fee-4a3d-8584-913fd3089c92/info.json" media="openseadragon" />')
  end
end
