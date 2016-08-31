require 'capybara/rspec'
require 'rails_helper'

RSpec.feature "Image Viewing", :type => :feature, :js => true do
  scenario 'the multiresimage info.json is in the OSD-generated html' do
    m = Multiresimage.first
    visit "#{Capybara.app_host}/multiresimages/#{m.pid}"
    expect(page).to have_css 'div.openseadragon-container'
    expect(page.html).to include("<source src=\"/image-service/#{m.pid.gsub(/:/, '-')}/info.json\" media=\"openseadragon\" />")
  end
end
