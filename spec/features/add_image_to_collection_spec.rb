require 'capybara/rspec'
require 'spec_helper'
require 'rake'

Capybara.default_driver = :selenium

describe 'Add an Image to a Collection',  :js => true do
  it "drags a draggable image element to a droppable collection element" do
   
    @driver = Capybara.default_driver
    #will these run without first running the rake hydra:fixture:refresh command? confirm!!

    visit('https://localhost:3000/users/sign_in')

    fill_in 'username', :with => 'dpg674'
    fill_in 'password', :with => 'ix9bash6baif4biag)'
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