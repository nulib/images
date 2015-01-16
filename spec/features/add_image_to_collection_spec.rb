require 'capybara/rspec'
require 'rails_helper'
require 'rake'

# README: Run the rake hydra:fixtures:refresh command besides the db:test:prepare commands in order to have
# images present. Also for now I just run it alone with the rspec spec/features/add_image_to_collection_spec.rb command.

# You'll also need to have firefox 24 installed to run the tests, and make sure rails is running in another tab.
# need a teardown that removes each image from collection after each test
# 12/19 - using fixture data like "Marche" for search term; new gem for maintaining session among specific tests
# you need a .env file with the credentials in it, in your root directory, also.


Capybara.default_driver = :selenium

# Utility functions

def drag_n_drop(source, target)
  source.drag_to(target)
end

def make_test_group(name)
  fill_in('new_dil_collection_title', with: name)
  page.evaluate_script("document.forms[1].submit()")
  sleep(10)
end

def add_images_to_test_group(name)
  #add images to name (test group)
  fill_in('q', with: "every man")
  page.evaluate_script("document.forms[0].submit()")
  sleep(10)

  #you need unique images
  #this is the best way to reference the image element, because it doesn't contain a pid or url, and the link with caption is below it
  source = page.find("#images li:first-child img")
  target = page.find('a', :text => name)

  drag_n_drop(source, target)

  visit('https://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
  sleep(10)

  source2 = page.find("#images li:first-child img")
  target2 = page.find("h2.ui-droppable:first-child a")

  drag_n_drop(source2, target2)


  visit('https://localhost:3000/catalog?f[worktype_facet][]=Prints')
  sleep(10)

  source3 = page.find("#images li:first-child img")
  target3 = page.find("h2.ui-droppable:first-child a")

  drag_n_drop(source3, target3)
  sleep(10)
end

def delete_test_group(name)
  # Delete test group
  visit('https://localhost:3000/')
  sleep(10)
  within('#imageCollection') do
    click_link(name)
  end
  sleep(10)
  click_link('Delete')

  page.driver.wait_until(page.driver.browser.switch_to.alert.accept)
end

def remove_images_from_test_group(name)
  visit('https://localhost:3000')
  sleep(10)

  click_link(name)

  sleep(10)

  all('.member-remove').each do |el|
    el.click()
    sleep(10)
  end
end

#Tests

steps 'Logged-in Users can Manage their Groups of Images',  :js => true do
  before :all do
    @driver = Capybara.default_driver
    visit('https://localhost:3000/users/sign_in')

    fill_in 'username', :with => ENV["TEST_USER_ID"]
    fill_in 'password', :with => ENV["TEST_USER_PASSWORD"]
    click_button('signIn')
    sleep(10)
  end


  it "lets a user add an image to a group" do
    #DIL-4095
    visit('https://localhost:3000')
    sleep(10)
    make_test_group('Test Group')

    visit('https://localhost:3000/catalog?f[worktype_facet][]=Prints')
    source = page.find("#images li:first img")
    source_title = page.find("#documents div:first .listing a")
    img_href = source_title[:href]

    target = page.find("h2.ui-droppable:first a")
    target_text = target.text()

    img_base_src = img_href.split("inu:")[1]
    drag_n_drop(source, target)
    sleep(10)
    click_link(target_text)

    sleep(10)
    image_present = false

    all('img').each do |img|
      if img[:src].include?(img_base_src)
        image_present = true
      end
    end

    image_present.should be_true

    delete_test_group('Test Group')
    sleep(10)
  end

 it "lets a user export to PowerPoint" do
   #DIL-4085
   visit('https://localhost:3000')
   sleep(10)
   make_test_group('PPT Group')

   visit('https://localhost:3000/catalog?f[worktype_facet][]=Prints')
   source = page.find("#images li:first img")
   source_title = page.find("#documents div:first .listing a")
   img_href = source_title[:href]

   target = page.find("h2.ui-droppable:first a")
   target_text = target.text()

   img_base_src = img_href.split("inu:")[1]
   drag_n_drop(source, target)
   sleep(10)
   click_link(target_text)

   sleep(10)
   click_link("Export to PowerPoint")

   page.should have_content('Image Group exported. Please check your Northwestern University email account for a link to your presentation.')

   delete_test_group('PPT Group')
   sleep(10)
 end

  it "lets a user search with a keyword" do
    # DIL-4069
    fill_in('q', with: 'every man')
    page.evaluate_script("document.forms[0].submit()")
    sleep(10)

    results = false

    all('.listing a').each do |el|

      if el.text().include?('Every man')
        results = true
      end
    end
    expect(results).to be_true

  end

  it "lets a user add an image to a group from the image view page" do

    # this test adds an image, saving a reference to its href, then goes to the group's page
    # and confirms an element with that href is on the page, then deletes the item from the test group
    # DIL-4082

    visit('https://localhost:3000')
    sleep(10)
    make_test_group('Test Group')
    sleep(10)

    visit('https://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
    img = page.find("#documents div:first .listing a")

    img_caption = img[:href]

    page.find("#images li:first img").click()

    sleep(10)

    click_button('Add to Image Group')
    sleep(10)
    select('Test Group')
    click_button('Save')
    sleep(10)

    visit('https://localhost:3000/')
    sleep(10)

    page.find('a', :text => 'Test Group').click()
    sleep(10)

    expect(page).to have_selector('a', :href => img_caption)
    delete_test_group('Test Group')
    sleep(10)
  end


  it "lets a user add a subgroup to a group" do
    # drag it onto the test group
    # test that if you click the subgroup it has the correct parent group in its page
    # and that if you click the expand button on the parent group you see the subgroup name
    # underneath it
    #DIL-4081
    visit('https://localhost:3000')
    sleep(10)
    make_test_group('Test Group')
    sleep(10)
    make_test_group('Test Subgroup')
    sleep(10)

    group = '', subgroup = '', group_parent = false

    all('.accordion li').each do |el|
      within(el) do
        h2 = find(:css, 'h2')
        if h2[:title] == "Test Group"
          sleep(10)
          group = h2
        end

        if h2[:title] == "Test Subgroup"
          sleep(10)
          subgroup = h2
        end
      end
    end

    drag_n_drop(subgroup, group)

    sleep(10)
    page.should_not have_selector('a', :text => 'Test Subgroup')

    within(group) do
      icon = find('span')
      within(icon) do
        find('img').click()
      end
    end

    sleep(10)
    our_subgroup = false
    our_subgroup = all('a').select{|a| a[:text] == 'Test Subgroup' }
    expect(our_subgroup).to be_true

    click_link('Test Subgroup')
    sleep(10)

    h4 = page.find('#sidebar div:first-child h4')
    sleep(10)
    a = page.find('#sidebar div:nth-child(2) a')

    if h4.text() == 'Parent Collections' and a[:text] == 'Test Group'
      group_parent = true
    end

    expect(group_parent).to be_true
    click_link('Delete')

    page.driver.wait_until(page.driver.browser.switch_to.alert.accept)

    delete_test_group('Test Group')
    sleep(10)
  end


  it 'lets a user navigate to next and previous images in a group' do
    # these tests assume that the images in first, 6th and 8th place are different, will have different urls.
    # they are fixture data so should be consistent.
    #DIL-4084
    visit('https://localhost:3000')
    sleep(10)
    make_test_group('Test Group')
    sleep(10)

    add_images_to_test_group('Test Group')
    sleep(10)

    visit('https://localhost:3000')

    sleep(10)

    click_link('Test Group')

    sleep(10)

    first_title = page.find("#gallery_container #images:first-child a")
    first_href = first_title[:href]

    second_title = page.find("#gallery_container #images:nth-child(2) a")
    second_href = second_title[:href]

    # click the first image, which should be first title. click next and the href on the
    # page should be the second title. on that page click previous, you should go back to page and see the first href there

    page.find("#images li:first-child img").click()
    sleep(10)
    click_link('Next')

    #the page's main image, the image available for download, is the second or first one
    expect(page).to have_selector('a', :href => second_href, :text => 'Small Image Download (JPG)')

    click_link('Previous')
    sleep(10)

    expect(page).to have_selector('a', :href => first_href, :text => 'Small Image Download (JPG)')
    sleep(10)

    #remove_images_from_test_group('Test Group')
    delete_test_group('Test Group')
  end


  it "lets a user make a group private" do
    #DIL-4087
    visit('https://localhost:3000')
    make_test_group('Test Group')
    sleep(10)

    click_link('Test Group')
    sleep(10)

    click_link('Make this Group Private')
    sleep(10)

    expect(page).to_not have_selector('a', :text => 'Share this Group')
    expect(page).to have_selector('a', :text => 'Make this Group Sharable')

    #cleanup - make the group public again
    click_link('Make this Group Sharable')
    delete_test_group('Test Group')
    sleep(10)
  end

  it "lets a user share a group" do
    #DIL-4087
    visit('https://localhost:3000')
    make_test_group('Test Group')

    sleep(10)
    group = find('a', :text => 'Test Group')
    group_url = group[:href]

    click_link('Test Group')
    sleep(10)
    click_link('Share this Group')
    sleep(10)
    #expect box with url in it to appear, also share this group copy
    expect(page).to have_css('#copypath', :href => group_url)
    share_box = find('#toppathwrap')
    sleep(10)

    expect(share_box.text.include?('Copy this link and share it!')).to be_true

    delete_test_group('Test Group')
    sleep(10)
  end


  it "lets a user delete a subgroup" do
    #DIL-4088
    visit('https://localhost:3000')
    sleep(10)
    make_test_group('Test Group')
    sleep(10)
    make_test_group('Test Subgroup')

    group = '', subgroup = ''

    all('.accordion li').each do |el|
      within(el) do
        h2 = find('h2')
        if h2[:title] == "Test Group"
          sleep(10)
          group = h2
        end

        if h2[:title] == "Test Subgroup"
          sleep(10)
          subgroup = h2
        end
      end
    end

    drag_n_drop(subgroup, group)

    sleep(10)

    click_link('Test Group')
    sleep(10)

    page.should have_selector('#images')
    page.find('.member-remove').click()

    sleep(10)
    page.should_not have_selector('#images')


    delete_test_group('Test Group')


    sleep(10)
    click_link('Test Subgroup')
    sleep(10)
    click_link('Delete')

    page.driver.wait_until(page.driver.browser.switch_to.alert.accept)
    sleep(10)
   end


  it "lets a user delete a group" do
    #DIL-4090
    visit('https://localhost:3000')

    make_test_group('Test Group')
    sleep(10)
    expect(page).to have_content('Test Group')

    delete_test_group('Test Group')
    sleep(10)
    expect(page).to_not have_content('Test Group')
    #cleanup - each tests creates and deletes test group
  end

  it "lets a user rename a group" do
    visit('https://localhost:3000')

    make_test_group('Test Group')
    sleep(10)

    click_link("Test Group")
    sleep(10)

    click_button('rename_image_group_link')
    fill_in('dil_collection_title', with: "New and Different Subgroup Name")
    page.evaluate_script("document.forms[2].submit()")
    sleep(10)

    group_title = find('#accordion h2')

    expect(group_title.text()).to eq("New and Different Subgroup Name")

    #clean up by re-naming back to Test Group
    click_button('rename_image_group_link')
    fill_in('dil_collection_title', with: "Test Group")
    page.evaluate_script("document.forms[2].submit()")
    sleep(10)

    #cleanup - delete test group
    delete_test_group('Test Group')
  end


  it "lets a user save a TIFF or jpeg" do
    #DIL-4091
    # click the download original tiff or jpeg button
    # and test that you get a page with an image file on with the correct src - jpg or tiff
    visit('https://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
    page.find(:css, "#images li:first img").click()

    sleep(10)
    img = page.find('a', :text => "Small Image Download (JPG)")

    pid = img[:href].split("inu:")[1]

    click_link('Small Image Download (JPG)')

    sleep(10)

    new_window = page.driver.browser.window_handles.last

    image_present = false

    page.within_window new_window do

      all('img').each do |img|
        if img[:src].include?(pid)
          image_present = true
        end
      end
    end

    image_present.should be_true
  end

  # it "lets you make a detail from an image" do

  #   #change this test. create test group. add images to test group.
  #   #create detail, confirm detail is in group too. then just delete test group.

  #   visit('https://localhost:3000')
  #   sleep(10)
  #   make_test_group('Test Group')
  #   sleep(10)
  #   add_images_to_test_group('Test Group')
  #   sleep(10)

  #   click_link('Test Group')
  #   sleep(10)

  #   page.find("#images li:first img").click()

  #   sleep(10)

  #   original_h1 = find(".page-header h1").text()
  #   expect(page).to_not have_content('My Image Details')

  #   #img = find(:xpath, '//div[@id="crop-tool"]/*[name()="svg"]/*[name()="image"]')

  #   svg = find(:xpath, '//div[@id="crop-tool"]/*[name()="svg"]')

  #   camera = ''

  #   within(svg) do
  #     all(:xpath, '*[name()="image"]').each do |el|
  #       if el[:href] == "/assets/croptool/camera.png"
  #         camera = el
  #       end
  #     end
  #   end

  #   sleep(10)
  #   camera.click()

  #   page.driver.wait_until(page.driver.browser.switch_to.alert.accept)
  #   sleep(10)

  #   new_h1 = find(".page-header h1").text()

  #   expect("#{original_h1} [DETAIL]").to eq(new_h1)
  #   expect(page).to have_content('My Image Details')

  #   #expect to see image on image details page, as well as test group page

  #   click_link('My Image Details')
  #   sleep(10)
  #   expect(page).to have_content(new_h1)


  #   click_link('Test Group')
  #   sleep(10)
  #   expect(page).to have_content(new_h1)


  #   delete_test_group('Test Group')
  #   sleep(10)


  #   click_link('My Image Details')
  #   sleep(10)

  #   click_link('Delete')

  #   sleep(10)
  #   page.driver.wait_until(page.driver.browser.switch_to.alert.accept)

  #   sleep(10)
  # end

end

steps "Logged out users can use Images too",  :js => true do
  it "lets you do a facets (narrowing) search" do
    #Dil-4093
    visit("https://localhost:3000")
    sleep(10)

    result_count = ''
    all('.facets-collapse div').each do |parent_el|
      h5 = parent_el.find('h5')
      if h5.text() == 'Work Type'
        h5.click()
        sleep(10)
        result_count = parent_el.find('ul li .count')
      end
    end

    sleep(10)

    expect(result_count.text()).to eq('3')
    sleep(10)
  end
end

