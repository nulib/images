require 'spec_helper'

describe Multiresimage do
  describe "a new instance with a file name" do
    subject { Multiresimage.new(:file_name=>'readme.txt') }
    its(:file_name) { should  == 'readme.txt' }
  end
  describe "should belong to a collection" do
    before do
      @collection = FactoryGirl.create(:collection)
    end
    subject { Multiresimage.new(:collection=>@collection) }
    its(:collection) { should == @collection } 
  end
  
  describe "created with a file" do
    before do
      @file = File.open(Rails.root.join("spec/fixtures/images/The_Tilled_Field.jpg"), 'rb')
      @file.stub(:original_filename => "The_Tilled_Field.jpg")
      @file.stub(:content_type =>"image/jpeg")
      @subject = Multiresimage.new
      @subject.attach_file([@file])
      @subject.save!
      @file.rewind
    end

    it "should store the contents in the 'raw' datastream" do
      @subject.raw.content.should == @file.read
    end

    it "should store the mimeType of the 'raw' datastream" do
      @subject.raw.mimeType.should == 'image/jpeg' 
    end

    it "should have to_jq_upload" do
      @subject.stub(:pid =>'my:pid')
      @subject.to_jq_upload.should == { :name=> "The_Tilled_Field.jpg", :size=>98982, :delete_url=>'/multiresimages/my:pid', :delete_type=>'DELETE', :url=>'/multiresimages/my:pid'}
    end

    describe "write_out_raw" do
      before do
        @subject.stub(:pid =>'my:pid')
      end
      subject {@subject.write_out_raw}
      it { should match /\/tmp\/The_Tilled_Field.jpg#{$$}\.0/ } 
      after do
        `rm #{subject}`
      end

    end
  end

  context "with a vra datastream" do
    subject { Multiresimage.find('inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26') }
    it "should have related_ids" do
      subject.related_ids.should == ["inu:dil-0b63522b-1747-47b6-9f0e-0d8f0710654b"]
    end
  end

  context "with rightsMetadata" do
    subject do
      m = Multiresimage.new()
      m.rightsMetadata.update_permissions("person"=>{"person1"=>"read","person2"=>"discover"}, "group"=>{"group-7"=>'read', 'group-8'=>'edit'})
      m.save
      m
    end
    it "should have read groups accessor" do
      subject.read_groups.should == ['group-7']
    end
    it "should have read groups writer" do
      subject.read_groups = ['group-2', 'group-3']
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    end
  end
end

