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
Capybara.default_wait_time = 5

# Utility functions

def drag_n_drop(source, target)
  source.drag_to(target)
end

def make_test_group(name)
  within('#new_dil_collection') do
    fill_in 'new_dil_collection_title', with: name
    click_button('Create Group')
  end
end

def add_images_to_test_group(name)
  #add images to name (test group)
  fill_in('q', with: "every man")
  click_button('search')

  #you need unique images
  #this is the best way to reference the image element, because it doesn't contain a pid or url, and the link with caption is below it
  source_li = page.find("#images li", match: :first)
  source = source_li.find("img")
  target = page.find('a', text: name)

  drag_n_drop(source, target)

  visit('http://localhost:3000/')

  find_link('Creator').click
  find_link('U.S. G.P.O.').click

  source_li2 = page.find("#images li", match: :first)
  source2 = source_li2.find("img")
  target2 = page.find('a', :text => name)

  drag_n_drop(source2, target2)

  visit('http://localhost:3000/')

  find_link('Work Type').click
  find_link('Prints').click

  source_li3 = page.find("#images li", match: :first)
  source3 = source_li3.find("img")
  target3 = page.find('a', :text => name)

  drag_n_drop(source3, target3)
end

def delete_test_group(name)
  # Delete test group
  visit('http://localhost:3000/')
  click_link(name, match: :first)
  page.accept_confirm "Delete this group?" do
    click_link "Delete"
  end
  expect(page).to have_content('Image Group deleted')
end

def remove_images_from_test_group(name)
  visit('http://localhost:3000')
  click_link(name)
  all('.member-remove').each do |el|
    click_link(el)
  end
end

#Tests

steps 'Logged-in Users can Manage their Groups of Images',  :js => true do
  before :all do
    @driver = Capybara.default_driver
    visit('http://localhost:3000/users/sign_in')
    within("#new_user") do
      fill_in 'username', :with => Rails.application.secrets["test_user_id"]
      fill_in 'password', :with => Rails.application.secrets["test_user_password"]
    end
    click_button('signIn')
  end

  it "lets a user add an image to a group" do
    #DIL-4095
    visit('http://localhost:3000')
    make_test_group('Test Group')

    find_link('Work Type').click
    find_link('Prints').click
    titles = page.all("#documents > div:nth-child(1) > div > a")
    img_title = titles[0].text.split[0..3].join(" ")
    puts "Image Title: #{img_title}"

    # drag the first image result to the Test Group
    drag_n_drop(first("#images > ul > li > a > img"), find_link('Test Group'))

    click_link('Test Group')
    expect(page).to have_content(img_title)

    delete_test_group('Test Group')
  end

  it "lets a user export to PowerPoint" do
    #DIL-4085
    visit('http://localhost:3000')
    make_test_group('PPT Group')
    add_images_to_test_group('PPT Group')
    click_link('PPT Group')
    click_link('Export to PowerPoint')

    expect(page).to have_content('Image Group exported. Please check your Northwestern University email account for a link to your presentation.')

    delete_test_group('PPT Group')
  end

  it "lets a user search with a keyword" do
    # DIL-4069
    fill_in('q', with: 'every man')
    click_button('search')
    expect(find("#documents")).to have_content("Every man")
  end

  it "lets a user add an image to a group from the image view page" do

    # this test adds an image, saving a reference to its href, then goes to the group's page
    # and confirms an element with that href is on the page, then deletes the item from the test group
    # DIL-4082

    visit('http://localhost:3000')
    make_test_group('Test Group')
    find_link('Creator').click
    find_link('U.S. G.P.O.').click

    titles = page.all("#documents > div:nth-child(1) > div > a")
    img_title = titles[0].text.split[0..3].join(" ")

    first('#documents > div:nth-child(1) > div > a').click

    click_link('Add to Image Group')
    select('Test Group')
    click_button('Save')
    sleep(5)

    visit('http://localhost:3000/')
    click_link('Test Group')

    expect(page).to have_link(img_title)

    delete_test_group('Test Group')
  end

  it "lets a user add a subgroup to a group" do
    # drag it onto the test group
    # test that if you click the subgroup it has the correct parent group in its page
    # and that if you click the expand button on the parent group you see the subgroup name
    # underneath it
    #DIL-4081
    visit('http://localhost:3000')
    make_test_group('Test Group')
    make_test_group('Test Subgroup')

    drag_n_drop(find_link('Test Group'), find_link('Test Subgroup'))

    expect(find('#sidebar')).to have_no_content('Test Group')

    within('#sidebar') do
      icon = find('span')
      within(icon) do
        find('img').click()
      end
    end

    click_link('Test Group')
    expect(find('#sidebar').find('h4')).to have_content('Parent Collections')

    page.accept_confirm "Delete this group?" do
      click_link "Delete"
    end

    delete_test_group('Test Subgroup')
  end

  it 'lets a user navigate to next and previous images in a group' do
    # these tests assume that the images in first, 6th and 8th place are different, will have different urls.
    # they are fixture data so should be consistent.
    #DIL-4084
    visit('http://localhost:3000')
    make_test_group('Test Group')

    add_images_to_test_group('Test Group')

    visit('http://localhost:3000')

    click_link('Test Group')

    #fix this:
    titles = page.all("#images:first-child > a:nth-child(2)")
    first_title = titles[0].text.split[0..3].join(" ")
    second_title = titles[1].text.split[0..3].join(" ")

    first('#images > a').click

    click_link('Next')
    expect(page).to have_content(second_title)

    click_link('Previous')
    expect(page).to have_content(first_title)

    #remove_images_from_test_group('Test Group')
    delete_test_group('Test Group')
  end

  it "lets a user make a group private" do
    #DIL-4087
    visit('http://localhost:3000')
    make_test_group('Test Group')
    click_link('Test Group')
    click_link('Make this Group Private')
    expect(page).to_not have_link('Share this Group')
    expect(page).to have_link('Make this Group Sharable')

    #make the group public again
    click_link('Make this Group Sharable')
    expect(page).to have_link('Make this Group Private')
    delete_test_group('Test Group')
  end

  it "lets a user share a group" do
    #DIL-4087
    visit('http://localhost:3000')
    make_test_group('Test Group')
    click_link('Test Group')

    click_link('Share this Group')

    #expect box with url in it to appear, also share this group copy
    expect(find('#toppathwrap')).to have_content(current_path)
    expect(find('#toppathwrap')).to have_content('Copy this link and share it!')

    delete_test_group('Test Group')
  end

  it "lets a user delete a group" do
    #DIL-4090
    visit('http://localhost:3000')

    make_test_group('Test Group')
    expect(page).to have_content('Test Group')

    delete_test_group('Test Group')
    expect(page).to_not have_content('Test Group')
  end

  it "lets a user rename a group" do
    visit('http://localhost:3000')
    make_test_group('Test Group')
    click_link('Test Group')
    click_button('rename_image_group_link')
    fill_in('dil_collection_title', with: "New and Different Subgroup Name")
    click_button('Update')
    expect(find('#accordion h2')).to have_content('New and Different Subgroup Name')
    delete_test_group('New and Different Subgroup Name')
  end

  xit "lets a user save a TIFF or jpeg" do
    #DIL-4091
    # click the download original tiff or jpeg button
    # and test that you get a page with an image file on with the correct src - jpg or tiff
    visit('http://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
    page.find(:css, "#images li:first img").click()

    sleep(8)
    img = page.find('a', :text => "Small Image Download (JPG)")

    pid = img[:href].split("inu:")[1]

    click_link('Small Image Download (JPG)')

    sleep(8)

    new_window = page.driver.browser.window_handles.last

    image_present = false

    page.within_window new_window do

      all('img').each do |img|
        if img[:src].include?(pid)
          image_present = true
        end
      end
    end

    image_present.should be_truthy
  end

end

steps "Logged out users can use Images to",  :js => true do
  it "lets you do a facets (narrowing) search" do
    visit('http://localhost:3000')
    find_link('Work Type').click
    find_link('Prints').click
    expect(page).to have_selector('.listing', count: 6)
  end
end