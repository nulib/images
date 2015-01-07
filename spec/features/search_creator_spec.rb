require 'rails_helper'

describe 'Search for a creator or keyword' do
  describe 'after logging in' do
    before do
      user = FactoryGirl.create(:staff)
      login( user )
      visit( '/' )
    end

    it "searches for a creator" do
      fill_in( 'q', '"Wilde, Oscar, 1854-1900"' )
      click_button( 'search' )
      expect( page ).to have_selector( '#documents .listing', count: 3 )
    end
  end
end
