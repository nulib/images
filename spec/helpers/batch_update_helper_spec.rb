require 'spec_helper'

describe BatchUpdateHelper do
  describe "batch_update_active?" do
    it "should be off" do
      session[:batch_update_state] = 'off'
      helper.batch_update_active?.should be_false
    end
    it "should be on" do
      session[:batch_update_state] = 'on'
      helper.batch_update_active?.should be_true
    end
  end
end
