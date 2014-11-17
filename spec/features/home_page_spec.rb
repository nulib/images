require 'rails_helper'

describe 'home page' do
  describe 'index' do
    before do
      visit '/'
    end

    context "not logging in" do
      it "has a login link" do
        expect(page).to have_content("Login")
      end


    end

    context "logging in" do
      it "should try to log in" do
        click_link 'Login'
      end
    end

  end
end