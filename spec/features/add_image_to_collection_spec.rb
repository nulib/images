require 'capybara/rspec'
require 'spec_helper'
require 'rake'


# README: This test requires a collection to exist prior to running it. For the time being, whoever
# runs it locally needs to create a collection through the web interface (and add an image to that collection). And I needed to run
# the rake hydra:fixtures:refresh command besdies the db:test:prepare commands in order to have images present.
# Also for now I just run it alone with the rspec spec/features/add_image_to_collection_spec.rb command.

# You'll also need to have firefox 24 installed to run the tests, and make sure rails is running in another tab.


Capybara.default_driver = :selenium

describe 'Add an Image to a Collection',  :js => true do
  it "drags a draggable image element to a droppable collection element" do

    @driver = Capybara.default_driver
    visit('https://localhost:3000/users/sign_in')

    fill_in 'username', :with => 'dpg674'
    fill_in 'password', :with => 'ih6bbiag)aif4x9bas'
    click_button('signIn')

    visit('https://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')

    source = page.find(:css, "#images li:first img")
    title = page.find(:css, "#documents div:first .listing a")
    img_href = title[:href]

    target = page.find(:css, "h2.ui-droppable:first a")
    target_text = target.text()

    img_base_src = img_href.split("inu:")[1]
    source.drag_to(target)
    sleep(4)

    click_link(target_text)

    sleep(5)
    image_present = false

    all('img').each do |img|
      if img[:src].include?(img_base_src)
        image_present = true
      end
    end

    image_present.should be_true
  end
end