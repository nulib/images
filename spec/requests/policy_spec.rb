require 'spec_helper'

describe "Policies" do
  pending("Pending the addition of Policies") do
  context "Given I have edit access" do
    let(:user) { FactoryGirl.find_or_create(:joe_creator) }
    let(:policy) { AdminPolicy.new }
    before  do
      policy.apply_depositor_metadata(user.user_key)
      policy.save
      login user
    end 
    after do
      policy.delete
    end
    context "When visiting edit" do
      before { visit edit_policy_path(policy.pid) }
      it "Then I should see a form for editing descriptive metadata" do
        page.should have_selector "form[action='#{policy_path(policy.pid)}']"
      end
      it "Then I should not have the ability to remove my own access" do
        page.should_not have_selector("#admin_policy_permissions_user_joe_creator")
      end
    end
  end end
end

