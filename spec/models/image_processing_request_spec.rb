require 'spec_helper'

describe ImageProcessingRequest do
  describe "accessing properties" do
    subject {ImageProcessingRequest.new(:pid=>'changeme:1')}
    its(:pid) {should == 'changeme:1'}
  end
  describe "a stored request" do
    before do
      @image = Multiresimage.new
      @image.update_attributes(:file_name =>'foo.jpg')
    end
    subject {ImageProcessingRequest.create!(:pid=>@image.pid, :email=>'test@example.com', :status=>'NEW')}
    it "should enqueue" do
      file_path = "/tmp/foo.jpg#{$$}.0"
      cgi_url = "http://www.example.com/cgi-bin/hydra/hydra-jms.cgi?image_path=#{file_path}&request_id=#{subject.id}"

      Net::HTTP.should_receive(:get_response).with(URI.parse(cgi_url)).and_return(stub(:body=>'hey'))
      subject.enqueue
    end
  end

end

