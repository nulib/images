require 'rails_helper'

describe Multiresimage do
  pending("It doesn't look like we're using policies and we should") do
    before do
      @policy = AdminPolicy.create
    end
    after do
      @policy.delete
    end
    subject { Multiresimage.new(admin_policy: @policy) }
    its(:admin_policy) { should == @policy }
  end

  describe '#create_datastreams_and_persist_image_files' do
    it 'creates and persists datastreams and derivatives from a tiff image and vra xml' do
      path = Rails.root.join('spec', 'fixtures', 'images', 'internet.tiff')
      count = Multiresimage.all.count

      @xml_from_menu = File.read(Rails.root.join('spec', 'fixtures', 'vra_image_sample.xml'))
      @img = Multiresimage.create(from_menu: true, vra_xml: @xml_from_menu, pid: 'inu:dil-67891234')
      all_good = @img.create_datastreams_and_persist_image_files(path)

      expect(all_good).to be true
      expect(count + 1).to eql(Multiresimage.all.count)
    end

    it 'will delete images and vra works if an error is raised in their creation' do
      @xml_from_menu = File.read(Rails.root.join('spec', 'fixtures', 'vra_image_sample.xml'))
      image_count = Multiresimage.all.count
      vra_count = Vrawork.all.count

      @img = Multiresimage.new(from_menu: true, vra_xml: @xml_from_menu, pid: 'inu:dil-67894321')
      @img.save

      expect{ @img.create_datastreams_and_persist_image_files('invalid_path') }.to raise_error(RuntimeError, 'Error when running JHOVE against invalid_path')
      expect(image_count).to eql(Multiresimage.all.count)
      expect(vra_count).to eql(Vrawork.all.count)
    end

    it 'can add the location display element that holds the pid to vra xml if it is missing' do
      path = Rails.root.join('spec', 'fixtures', 'images', 'internet.tiff')
      count = Multiresimage.all.count

      @xml_from_menu = File.read(Rails.root.join('spec', 'fixtures', 'vra_without_locationset_display.xml'))
      @img = Multiresimage.create(from_menu: true, vra_xml: @xml_from_menu, pid: 'inu:dil-43216789')
      all_good = @img.create_datastreams_and_persist_image_files(path)

      expect(all_good).to be true
      expect(count + 1).to eql(Multiresimage.all.count)
    end
  end

  describe '#vra_save' do
    before(:each) do
      @xml_from_menu = File.read(Rails.root.join('spec', 'fixtures', 'vra_image_sample.xml'))
      @m = Multiresimage.create(from_menu: true, vra_xml: @xml_from_menu, pid: 'inu:dil-98761234')
    end

    it 'creates the appropriate vra:image XML' do
      xml_from_rir = File.read(Rails.root.join('spec', 'fixtures', 'vra_image_sample_complete.xml'))
      doc1 = Nokogiri::XML(@m.datastreams['VRA'].to_xml)
      doc2 = Nokogiri::XML(xml_from_rir)
      expect(doc1).to be_equivalent_to(doc2).ignoring_content_of(['vra|locationSet']).ignoring_attr_values('relids', 'refid', 'id')
    end

    it 'ensures object type facet is correct' do
      expect(@m.VRA.to_solr['object_type_facet']).to eq ['Multiresimage']
    end
  end

  context 'create datastreams' do
    before(:each) do
      @m = Multiresimage.create
      @sample_tiff = Rails.root.join('spec', 'fixtures', 'images', 'internet.tiff')
    end

    describe '#create_archv_img_datastream' do
      it 'populates the ARCHV-IMG datastream' do
        @m.create_archv_img_datastream('http://upload.wikimedia.org/wikipedia/commons/0/0e/Haeberli_off_luv24.tif')
        @m.save!
        expect(@m.datastreams['ARCHV-IMG'].content).to_not be_nil
      end
    end

    describe '#create_archv_techmd_datastream' do
      it 'populates the ARCHV-TECHMD datastream' do
        jhove_xml = Nokogiri::XML.parse(File.read(Rails.root.join('spec', 'fixtures', 'archv_jhove_output.xml')))
        @m.create_archv_techmd_datastream(@sample_tiff)
        expect(@m.datastreams['ARCHV-TECHMD'].content).to be_equivalent_to(jhove_xml).ignoring_content_of('date')
      end
    end

    describe '#create_archv_exif_datastream' do
      it 'populates the ARCHV-EXIF datastream' do
        exif_xml = `#{ Rails.root }/lib/exif.pl #{ @sample_tiff }`
        sleep 1
        @m.create_archv_exif_datastream(@sample_tiff)
        expect(@m.datastreams['ARCHV-EXIF'].content).to match_xml_except(exif_xml, 'File_Access_Date_Time', 'File Access Date/Time')
      end
    end
  end

  # We don't have working/updated factories right now
  pending 'should belong to multiple collections' do
    before do
      @collection1 = FactoryGirl.create(:collection)
      @collection2 = FactoryGirl.create(:collection)
      @collection3 = FactoryGirl.create(:collection)
    end
    subject { Multiresimage.new(collections: [@collection1, @collection2]) }
    its(:collections) { should == [@collection1, @collection2] }
  end


  context 'to_solr' do
    before do
      @img = Multiresimage.new
      @img.titleSet_display = 'Evanston Public Library. Exterior: facade'
    end
    subject { @img.to_solr }
    it 'should have title_display' do
      expect(subject['title_display']).to eq 'Evanston Public Library. Exterior: facade'
    end
  end

  context 'with rightsMetadata' do
    subject do
      m = Multiresimage.new
      m.rightsMetadata.update_permissions('person' => { 'person1' => 'read', 'person2' => 'discover' }, 'group' => { 'group-6' => 'read', 'group-7' => 'read', 'group-8' => 'edit' })
      m.save
      m
    end

    it 'should have read groups accessor' do
      expect(subject.read_groups).to eq ['group-6', 'group-7']
    end

    it 'should have read groups writer' do
      subject.read_groups = ['group-2', 'group-3']
      expect(subject.rightsMetadata.groups).to eq('group-2' => 'read', 'group-3' => 'read', 'group-8' => 'edit')
      expect(subject.rightsMetadata.users).to eq('person1' => 'read', 'person2' => 'discover')
    end

    it 'should only revoke eligible groups' do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      expect(subject.rightsMetadata.groups).to eq('group-2' => 'read', 'group-3' => 'read', 'group-7' => 'read', 'group-8' => 'edit')
      expect(subject.rightsMetadata.users).to eq('person1' => 'read', 'person2' => 'discover')
    end
  end
end
