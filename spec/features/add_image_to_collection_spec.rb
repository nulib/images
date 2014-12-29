require 'capybara/rspec'
require 'spec_helper'
require 'rake'

# README: This test requires a collection to exist prior to running it. For the time being, whoever
# runs it locally needs to create a collection through the web interface (and add an image to that collection). And I needed to run
# the rake hydra:fixtures:refresh command besdies the db:test:prepare commands in order to have images present.
# Also for now I just run it alone with the rspec spec/features/add_image_to_collection_spec.rb command.

# You'll also need to have firefox 24 installed to run the tests, and make sure rails is running in another tab.
# need a teardown that removes each image from collection after each test 
# 12/19 - using fixture data like "Marche" for search term; new gem for maintaining session among specific tests

Capybara.default_driver = :selenium


def drag_n_drop(source, target)
  source.drag_to(target)
end

def cleanup
  # Delete test group
  #click, wait, click delete 
  visit('https://localhost:3000/')

  #click_link('Test Group')
  within('#imageCollection') do
    puts 'hello'
    click_link('Test Group')
  end
  sleep(4)
  click_link('Delete')
  sleep(4)
 # page.accept_alert 'Delete this group?' do
 #try this instead: 
 #page.driver.browser.execute_script
 #https://groups.google.com/forum/?fromgroups=#!topic/ruby-capybara/YcZwyPdMJFU
  click_button('OK')
#  end

end


steps 'Users can Manage their Groups of Images',  :js => true do
    before :all do
      @driver = Capybara.default_driver
      visit('https://localhost:3000/users/sign_in')

      fill_in 'username', :with => ENV["TEST_USER_ID"]
      fill_in 'password', :with => ENV["TEST_USER_PASSWORD"]
      click_button('signIn')
      sleep(2)
      #it would be really fantastic to have a group created here. 
     
      #LIKE THIS ONE
      # fill_in('new_dil_collection_title', with: 'Test Group')
      # page.evaluate_script("document.forms[1].submit()")
      # sleep(4)

    end

    #this might be unnecessary because after happens after steps? -- well -- would need to be done somehow within a step. maybe a cleanup step.
  
  # it "lets a user add an image to a group" do
  #   visit('https://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
  #   source = page.find(:css, "#images li:first img")  
  #   source_title = page.find(:css, "#documents div:first .listing a")
  #   img_href = source_title[:href]

  #   target = page.find(:css, "h2.ui-droppable:first a")
  #   target_text = target.text()
    
  #   img_base_src = img_href.split("inu:")[1]
  #   drag_n_drop(source, target)
  #   sleep(4)
  #   click_link(target_text)
    
  #   sleep(5)
  #   image_present = false
    
  #   all('img').each do |img| 
  #     if img[:src].include?(img_base_src) 
  #       image_present = true 
  #     end
  #   end
  #   image_present.should be_true
  # end

  # it "lets a user search with a keyword" do
  #   fill_in('q', with: 'Marche')
  #   page.evaluate_script("document.forms[0].submit()")
  #   sleep(5)

  #   expect(page).to have_css("a", :text => "Marche")
  # end

  it "lets a user add a subgroup to a group" do 
    pending
    #check it out, you CAN create a test group.
    # fill_in('new_dil_collection_title', with: 'Test Subgroup')
    # page.evaluate_script("document.forms[1].submit()")  
    # sleep(2)
  end

  it "cleans up after itself" do
    cleanup
  end


end