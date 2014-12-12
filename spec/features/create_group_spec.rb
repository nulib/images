require 'rails_helper'

describe 'Create a new group' do
  describe 'after logging in' do
    before do
      user = FactoryGirl.create(:staff)
      login( user )
      visit( '/' )
    end

    it "searches for a creator" do
      fill_in( 'q', '*' )
      click_button( 'search' )
      fill_in( 'new_dil_collection_title', 'test_group_1' )
      find( '#new_dil_collection_title' ).native.send_key( :Enter )
      expect( page ).to have_content( 'test_group_1' )
    end
  end
end
