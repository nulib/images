require 'spec_helper'
 describe "load an object" do
    it "should load within 5 seconds" do
      start_time = Time.now
      @object = Multiresimage.find("inu:dil-6ef3b0ac-6083-4027-89a3-139322c1c2a4")
      end_time = Time.now
      
      (end_time - start_time).should <= 5
    end
  end