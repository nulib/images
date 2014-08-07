require 'spec_helper'

describe Multiresimage do

  describe "a new instance with a file name" do
    subject { Multiresimage.new(:file_name=>'readme.txt') }
    its(:file_name) { should  == 'readme.txt' }
  end

  pending("It doesn't look like we're using policies") do
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
  end

  context "create datastreams" do

    before( :each ) do
      @m = Multiresimage.create
      @sample_tiff = "#{Rails.root}/spec/fixtures/images/internet.tiff"
      @sample_jp2  = "#{ Rails.root }/spec/fixtures/images/internet.jp2"
    end

    describe "#create_archv_techmd_datastream" do
      it "populates the ARCHV-TECHMD datastream" do
        @m.create_archv_techmd_datastream( @sample_tiff )
        jhove_xml = File.open( "#{Rails.root}/spec/fixtures/archv_jhove_output.xml" ).read
        expect( @m.datastreams["ARCHV-TECHMD"].content ).to match_xml_except( jhove_xml, 'date' )
      end
    end

    describe "#create_archv_exif_datastream" do
      it "adds the ARCHV-EXIF datastream" do
        exif_xml = `#{ Rails.root }/lib/exif.pl #{ @sample_tiff }`
        @m.create_archv_exif_datastream( @sample_tiff )
        expect( @m.datastreams[ "ARCHV-EXIF" ].content ).to match_xml_except( exif_xml, 'File_Access_Date_Time' )
      end
    end

    describe "#create_deliv_techmd_datastream" do
      it "adds the DELIV-TECHMD datastream" do
        jhove_xml = File.open("#{Rails.root}/spec/fixtures/deliv_jhove_output.xml").read
        @m.create_deliv_techmd_datastream( @sample_jp2 )
        expect( @m.datastreams[ "DELIV-TECHMD" ].content ).to match_xml_except( jhove_xml, 'date' )
      end
    end

    describe "#create_deliv_ops_datastream" do
      it "populates the DELIV-OPS datastream" do
        @m.create_deliv_techmd_datastream( @sample_jp2 )
        @m.create_deliv_ops_datastream( @sample_jp2 )
        deliv_ops_xml = <<-EOF
<svg:svg xmlns:svg=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">
  <svg:image x=\"0\" y=\"0\" height=\"664\" width=\"600\" xlink:href=\"inu-dil/hydra/test/#{ @m.pid }.jp2\"/>
</svg:svg>
EOF
        expect( @m.datastreams[ "DELIV-OPS" ].content).to eq( deliv_ops_xml.chomp )
      end
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

  context "with an associated work" do
    xml = File.open("#{Rails.root}/spec/fixtures/vra_image_minimal.xml")

    # this will create a vrawork and associate them with each other
    img = Multiresimage.create(vra_xml: xml, from_menu: true, pid: "my:pid")
    img.save

    it "should have related_ids" do
      img.related_ids.first.should eq img.vraworks.first.pid
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

