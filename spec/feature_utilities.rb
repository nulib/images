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

  #get three unique images

  source = page.find(".listing #images img", match: :first)
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