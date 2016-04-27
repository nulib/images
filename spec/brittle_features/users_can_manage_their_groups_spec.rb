require 'capybara/rspec'
require 'rails_helper'
require 'rake'
require 'feature_utilities'

Capybara.default_driver = :selenium
Capybara.default_wait_time = 5


RSpec::Steps.steps 'Logged-in Users can Manage their Groups of Images',  :js => true do
  before :all do
    @driver = :rack_test
    visit('http://localhost:3000/users/sign_in')
    within("#new_user") do
      fill_in 'username', :with => Rails.application.secrets["test_non_admin_id"]
      fill_in 'password', :with => Rails.application.secrets["test_non_admin_password"]
    end
    click_button('signIn')
  end


  it "lets a user add an image to a group" do
    #DIL-4095
    visit('http://localhost:3000')
    make_test_group('Test Group')

    find_link('Work Type').click
    find_link('Prints').click
    titles = page.all("#documents > div.blacklight-info-fedora-afmodel-multiresimage > div > a")

    img_title = titles[0].text.split[0..3].join(" ")

    # drag the first image result to the Test Group
    test_group = find_link('Test Group')
    img = find("#images > ul > li > a > img", match: :first)

    drag_n_drop(img, test_group)


    click_link('Test Group')
    sleep(5)
    expect(page).to have_content(img_title)

    delete_test_group('Test Group')
  end

  # just commenting it out
  #  it "lets a user export to PowerPoint" do
  #   pending
  #   #DIL-4085
  #   visit('http://localhost:3000')
  #   make_test_group('PPT Group')
  #   add_images_to_test_group('PPT Group')
  #   click_link('PPT Group')
  #   click_link('Export to PowerPoint')
  #
  #   expect(page).to have_content('Image Group exported. Please check your Northwestern University email account for a link to your presentation.')
  #
  #   delete_test_group('PPT Group')
  # end

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

    titles = page.all("#documents > div.blacklight-info-fedora-afmodel-multiresimage > div > a")
    img_title = titles[0].text.split[0..3].join(" ")

    first('#documents > div.blacklight-info-fedora-afmodel-multiresimage > div > a').click

    click_link('Add to Image Group')
    select('Test Group')
    click_button('Save')
    sleep(5)

    visit('http://localhost:3000/')
    click_link('Test Group')

    expect(page).to have_link(img_title)

    delete_test_group('Test Group')
  end

  it "won't display 'add an image to a group' unless user has groups" do
    find_link('Creator').click
    find_link('U.S. G.P.O.').click

    expect(page).to_not have_content("Add to Image Group")
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

    #separating out some text processing because selenium can't get out of first gear:

    titles = page.all("#images:first-child > a:nth-child(2)")
    first = titles[0].text
    first_title = first.split[0..3].join(" ")
    second = titles[1].text
    second_title = second.split[0..3].join(" ")

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


  # it "lets a user save a TIFF or jpeg" do
  #   #DIL-4091
  #   # click the download original tiff or jpeg button
  #   # and test that you get a page with an image file on with the correct src - jpg or tiff
  #   visit('http://localhost:3000/catalog?f%5Bagent_name_facet%5D%5B%5D=U.S.+G.P.O.')
  #   page.find(:css, "#images li:first img").click()

  #   sleep(8)
  #   img = page.find('a', :text => "Small Image Download (JPG)")

  #   pid = img[:href].split("inu:")[1]

  #   click_link('Small Image Download (JPG)')

  #   sleep(8)

  #   new_window = page.driver.browser.window_handles.last

  #   image_present = false

  #   page.within_window new_window do

  #     all('img').each do |img|
  #       if img[:src].include?(pid)
  #         image_present = true
  #       end
  #     end
  #   end

  #   image_present.should be_truthy
  # end

end