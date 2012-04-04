require 'spec_helper'

describe Multiresimage do
  it "should create with a file" do
    file = File.open(Rails.root.join("spec/fixtures/images/The_Tilled_Field.jpg"), 'rb')
    file.should_receive(:original_filename).and_return("The_Tilled_Field.jpg")
    img = Multiresimage.create(:files=>[file])

    file.rewind
    img.raw.content.should == file.read
    
  end

  it "should have to_jq_upload" do
    file = File.open(Rails.root.join("spec/fixtures/images/The_Tilled_Field.jpg"), 'rb')
    file.should_receive(:original_filename).and_return("The_Tilled_Field.jpg")
    img = Multiresimage.create(:files=>[file])
    img.should_receive(:pid).and_return('my:pid')
    img.to_jq_upload.should == { :name=> "The_Tilled_Field.jpg", :size=>98982, :delete_url=>'/multiresimages/my:pid', :delete_type=>'DELETE'}
    
  end

end

