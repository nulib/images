require "spec_helper"

describe "Catalog" do

  it "should have links to upload images " do
    visit catalog_index_path
    page.should have_selector("a[href='#{uploads_path}']", :text=>"Upload Images")

  end

end
