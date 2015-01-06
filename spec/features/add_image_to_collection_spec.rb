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
  visit('https://localhost:3000/')
  sleep(2)
  within('#imageCollection') do
    click_link('Test Group')
  end
  sleep(2)
  click_link('Delete')

  page.driver.wait_until(page.driver.browser.switch_to.alert.accept)
end


def make_test_group(name)
  fill_in('new_dil_collection_title', with: name)
  page.evaluate_script("document.forms[1].submit()")
  sleep(2)
end


steps 'Users can Manage their Groups of Images',  :js => true do
  before :all do
    @driver = Capybara.default_driver
    visit('https://localhost:3000/users/sign_in')

    fill_in 'username', :with => ENV["TEST_USER_ID"]
    fill_in 'password', :with => ENV["TEST_USER_PASSWORD"]
    click_button('signIn')
    sleep(2)
    make_test_group('Test Group')
  end
  
  it "lets a user add an image to a group" do
    #DIL-4095
    visit('https://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
    source = page.find(:css, "#images li:first img")  
    source_title = page.find(:css, "#documents div:first .listing a")
    img_href = source_title[:href]

    target = page.find(:css, "h2.ui-droppable:first a")
    target_text = target.text()
    
    img_base_src = img_href.split("inu:")[1]
    drag_n_drop(source, target)
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

  it "lets a user search with a keyword" do
    # DIL-4069
    fill_in('q', with: 'Party time')
    page.evaluate_script("document.forms[0].submit()")
    sleep(5)

    expect(page).to have_css("a", :text => "Party time")
  end

  it "lets a user add an image to a group from the image view page" do

    # this test adds an image, saving a reference to its href, then goes to the group's page
    # and confirms an element with that href is on the page, then deletes the item from the test group
    # DIL-4082

    visit('https://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
    img = page.find(:css, "#documents div:first .listing a")

    img_caption = img[:href]

    page.find(:css, "#images li:first img").click()

    sleep(2)

    click_button('Add to Image Group')
    sleep(2)
    select('Test Group')
    click_button('Save')
    sleep(2)

    visit('https://localhost:3000/')
    sleep(2)

    page.find('a', :text => 'Test Group').click()
    sleep(2)

    expect(page).to have_selector('a', :href => img_caption)
    page.find(:css, '.member-remove').click()

    sleep(2)
  end


  it "lets a user add a subgroup to a group" do 
    # drag it onto the test group
    # test that if you click the subgroup it has the correct parent group in its page
    # and that if you click the expand button on the parent group you see the subgroup name 
    # underneath it
    #DIL-4081
    visit('https://localhost:3000')
    sleep(2)
    make_test_group('Test Subgroup')

    group = '', subgroup = '', group_parent = false

    all('.accordion li').each do |el|
      within(el) do 
        h2 = find(:css, 'h2')
        if h2[:title] == "Test Group"
          sleep(2)
          group = h2
        end 
 
        if h2[:title] == "Test Subgroup"
          sleep(2)
          subgroup = h2
        end 
      end
    end

    drag_n_drop(subgroup, group)

    sleep(2)
    page.should_not have_selector('a', :text => 'Test Subgroup')
    
    within(group) do
      icon = find(:css, 'span')    
      within(icon) do  
        img = find(:css, 'img')        
        find(:css, 'img').click()       
      end
    end  

    sleep(2)
    our_subgroup = false
    our_subgroup = all('a').select{|a| a[:text] == 'Test Subgroup' }
    expect(our_subgroup).to be_true

    click_link('Test Subgroup')
    sleep(2)

    h4 = page.find('#sidebar div:first-child h4')
    sleep(2)
    a = page.find('#sidebar div:nth-child(2) a')

    if h4.text() == 'Parent Collections' and a[:text] == 'Test Group'
      group_parent = true
    end

    expect(group_parent).to be_true 

    #delete the subgroup
    sleep(2)
    click_link('Delete')

    page.driver.wait_until(page.driver.browser.switch_to.alert.accept)
  end



  it 'lets a user navigate to next and previous images in a group' do 
    # these tests assume that the images in first, 6th and 8th place are different, will have different urls.
    # they are fixture data so should be consistent.
    #DIL-4084
    #add two images to test group
    visit('https://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
    first_title = page.find(:css, "#documents div:first-child .listing a")
    first_href = first_title[:href]

    page.find(:css, "#images li:first-child img").click()
    sleep(2)
    click_button('Add to Image Group')
    sleep(2)
    select('Test Group')
    click_button('Save')
    sleep(8)

    visit('https://localhost:3000/catalog?f%5Bworktype_facet%5D%5B%5D=Photography%2C+Film+and+Video')
    sleep(3)
    
    second_title = page.find(:css, "#documents div:first-child .listing a")
    second_href = second_title[:href]  

    page.find(:css, "#images li:first-child img").click() 
    sleep(4)

    click_button('Add to Image Group')
    sleep(2)
    select('Test Group')
    click_button('Save')
    sleep(4)

    visit('https://localhost:3000/')
    sleep(2)

    page.find('a', :text => 'Test Group').click()
    sleep(3)


    # click the first image, which should be first title. click next and the href on the 
    # page should be the second title. on that page click previous, you should go back to page and see the first href there

    page.find(:css, "#images li:first-child img").click()
    sleep(4)
    click_link('Next')

    #the page's main image, the image available for download, is the second or first one
    expect(page).to have_selector('a', :href => second_href, :text => 'Small Image Download (JPG)')

    click_link('Previous')
    sleep(4)

    expect(page).to have_selector('a', :href => first_href, :text => 'Small Image Download (JPG)')
    sleep(1)

  end


  it "lets a user make a group private" do
    #DIL-4087
    click_link('Test Group')
    sleep(5)
    click_link('Make this Group Private')
    sleep(5)
    
    expect(page).to_not have_selector('a', :text => 'Share this Group')
    expect(page).to have_selector('a', :text => 'Make this Group Sharable')
  end

  it "lets a user share a group" do
    #DIL-4087
    group = find('a', :text => 'Test Group')
    group_url = group[:href]

    click_link('Test Group')
    sleep(5)
    click_link('Share this Group')

    #expect box with url in it to appear, also share this group copy
    expect(page).to have_css('#copypath', :href => group_url)
    share_box = find('#toppathwrap')
    sleep(2)

    expect(share_box.text.include?('Copy this link and share it!')).to be_true
  end

  it "cleans up after itself" do
    cleanup
  end


end