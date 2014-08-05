require 'spec_helper'

describe Multiresimage do

  describe "a new instance with a file name" do
    subject { Multiresimage.new(:file_name=>'readme.txt') }
    its(:file_name) { should  == 'readme.txt' }
  end

  describe "should have an admin policy" do
    before do
      @policy = AdminPolicy.create
    end
    after do
      @policy.delete
    end
    subject { Multiresimage.new(:admin_policy=>@policy) }
    its(:admin_policy) { should == @policy }

  end


  describe "jhove/techmd datastream" do
    it "populates the ARCHV-TECHMD datastream" do
      m = Multiresimage.create(pid: "my:pid")
      m.create_techmd_datastream("#{Rails.root}/app/assets/images/rails.png")
      expect( m.datastreams["ARCHV-TECHMD"].content ).to eq(File.open("#{Rails.root}/app/assets/images/jhove_output.xml").read )
    end
  end

  describe "#create_deliv-ops_datastream" do
    it "populates the DELIV-OPS datastream" do
      img = Multiresimage.create
      img.create_deliv_ops_datastream( "#{ Rails.root }/spec/fixtures/images/internet.tiff" )
      deliv_ops_xml = "<svg:svg xmlns:svg=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">  <svg:image x=\"0\" y=\"0\" height=\"600\" width=\"664\" xlink:href=\"inu-dil/hydra/test/#{ img.pid }.jp2\"/></svg:svg>"
      expect( img.datastreams[ "DELIV-OPS" ].content).to eq( deliv_ops_xml )
    end
  end

  describe "#create_archv_exif_datastream" do
    it "adds the archv-exif datastream" do
      m = Multiresimage.create
      sample_image_path = "#{Rails.root}/spec/fixtures/images/internet.tiff"
      exif_xml = `#{ Rails.root }/lib/exif.pl #{ sample_image_path }`
      m.create_archv_exif_datastream( sample_image_path )
      expect( m.datastreams[ "ARCHV-EXIF" ].content ).to eq( exif_xml )
    end
  end

  describe "#create_deliv_techmd_datastream" do
    it "adds the DELIV-TECHMD datastream" do
      m = Multiresimage.create
      sample_image_path = "#{Rails.root}/spec/fixtures/images/internet.jp2"
      jhove_xml = `#{ Rails.root }/lib/exif.pl #{ sample_image_path }`
      m.create_deliv_techmd_datastream( sample_image_path )
      expect( m.datastreams[ "DELIV-TECHMD" ].content ).to eq( exif_xml )
    end
  end

  describe "should belong to multiple collections" do
    before do
      @collection1 = FactoryGirl.create(:collection)
      @collection2 = FactoryGirl.create(:collection)
      @collection3 = FactoryGirl.create(:collection)
    end
    subject { Multiresimage.new(:collections=>[@collection1, @collection2]) }
    its(:collections) { should == [@collection1, @collection2] }
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
  context "to_solr" do
    before do
      @img = Multiresimage.new
      @img.titleSet_display = 'Evanston Public Library. Exterior: facade'
    end
    subject { @img.to_solr }
    it "should have title_display" do
      subject['title_display'].should == "Evanston Public Library. Exterior: facade"
    end
  end

  context "with rightsMetadata" do
    subject do
      m = Multiresimage.new()
      m.rightsMetadata.update_permissions("person"=>{"person1"=>"read","person2"=>"discover"}, "group"=>{'group-6' => 'read', "group-7"=>'read', 'group-8'=>'edit'})
      m.save
      m
    end
    it "should have read groups accessor" do
      subject.read_groups.should == ['group-6', 'group-7']
    end
    it "should have read groups writer" do
      subject.read_groups = ['group-2', 'group-3']
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    end
    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-7' => 'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    end
  end

  describe "update with an attached vrawork" do
    before do
      @img = Multiresimage.create
      @work = Vrawork.create
      @img.vraworks = [@work]
    end
    it "should update the work" do
      @img.update_attributes(:titleSet_display => "Woah cowboy")
      @img.vraworks.first.titleSet_display_work.should == "Woah cowboy"

    end
  end

  describe "with related works" do
    before do
      @img = Multiresimage.new
      @work1 = Vrawork.create
      @work2 = Vrawork.create
      @work3 = Vrawork.create
      vra_xml = <<-eos
      <vra:vra xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:vra="http://www.vraweb.org/vracore4.htm" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://www.vraweb.org/projects/vracore4/vra-4.0-restricted.xsd">
        <vra:image id="inu-dil-77334_w" refid="inu:dil-d42f25cc-deb2-4fdc-b41b-616291578c26">

          <vra:relationSet>
            <vra:display>Evanston Public Library. Exterior: facade</vra:display>
            <vra:relation pref="true" relids="#{@work1.pid}" type="imageOf">Evanston Public Library. Exterior: facade</vra:relation>
            <vra:relation relids="#{@work2.pid}" type="imageOf">Evanston Public Library. Exterior: facade</vra:relation>
            <vra:relation relids="#{@work3.pid}" type="imageOf">Evanston Public Library. Exterior: facade</vra:relation>
          </vra:relationSet>
        </vra:image>
      </vra:vra>
      eos
      @img.datastreams["VRA"] = VRADatastream.from_xml(vra_xml)
    end
    it "preferred_related_work should return the preferred work" do
      @img.preferred_related_work.should == @work1
    end
    it "other_related_works should be the others" do
      @img.other_related_works.should == [@work2, @work3]
    end
  end
end

