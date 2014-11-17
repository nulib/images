require 'rails_helper'

describe 'basic functionality' do
  describe 'from the home page' do
    before do
      visit '/'
    end

    context "and not logged in" do
      it "has a login link" do
        expect(page).to have_content("Login")
      end

      it "can pull up the login page" do
        click_link 'Login'
        expect(page).to have_content("Sign in with a NetID")
      end

      it "should log in" do
        user = FactoryGirl.create(:staff)
        # this is a method in support/login.rb
        login(user)
        expect(page).to have_content("Successfully authorized")
      end
    end

  end
end