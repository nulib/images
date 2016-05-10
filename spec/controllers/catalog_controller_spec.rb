require 'rails_helper'

describe CatalogController, :type => :request do

  describe "get catalog index page" do
    #the riiif server will return 500 for unfound thumbnails
    it "returns 200" do
      get catalog_index_path

      expect(response.status).to be(200)
    end
  end

end
