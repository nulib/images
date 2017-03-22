require 'rails_helper'

RSpec.describe VraValidator do
  class DummyClass
    include VraValidator
  end

  before(:each) do
    @dummy_class = DummyClass.new
  end

  it 'makes #valid_vra? available' do
    expect(@dummy_class).to respond_to(:valid_vra?)
  end

  it 'makes #vra_errors? available' do
    expect(@dummy_class).to respond_to(:vra_errors?)
  end

  describe '#get_validation_errors' do
    it 'returns an empty array for valid vra' do
      expect(@dummy_class.get_validation_errors(File.open(Rails.root.join('spec', 'fixtures', 'vra_image_minimal.xml')).read)).to be_empty
    end

    it 'returns an array of errors for invalid vra' do
      expect(@dummy_class.get_validation_errors(File.open(Rails.root.join('spec', 'fixtures', 'vra_image_minimal_invalid.xml')).read)).to eq ["Validation error: Element '{http://www.vraweb.org/vracore4.htm}earliestDate': [facet 'pattern'] The value '' is not accepted by the pattern 'present|(-)*[0-9]{1,12}(-[0-9]{2}(-[0-9]{2})*)*'.\n", "Validation error: Element '{http://www.vraweb.org/vracore4.htm}earliestDate': '' is not a valid value of the atomic type '{http://www.vraweb.org/vracore4.htm}dateValueType'.\n"]
    end
  end

  describe '#vra_errors?' do
    it 'returns true for invalid vra' do
      expect(@dummy_class.vra_errors?(File.open(Rails.root.join('spec', 'fixtures', 'vra_image_minimal_invalid.xml')).read)).to be_truthy
    end

    it 'returns false for valid vra' do
      expect(@dummy_class.vra_errors?(File.open(Rails.root.join('spec', 'fixtures', 'vra_image_minimal.xml')).read)).to be_falsey
    end

    it 'returns false for valid vra that has a locationSet refid containing an inu:dil pid' do
      expect(@dummy_class.vra_errors?(File.open(Rails.root.join('spec', 'fixtures', 'vra_image_with_pids.xml')).read)).to be_falsey
    end
  end
end
