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

  it 'makes #validate_vra available' do
    expect(@dummy_class).to respond_to(:validate_vra)
  end

  context 'validation' do
    describe 'with invalid vra' do
      it 'should fail' do
        expect(@dummy_class.valid_vra?(File.open(Rails.root.join('spec', 'fixtures', 'vra_image_minimal_invalid.xml')).read)).to be_falsey
      end
    end

    describe 'with valid vra' do
      it 'should pass' do
        expect(@dummy_class.validate_vra(File.open(Rails.root.join('spec', 'fixtures', 'vra_image_minimal.xml')).read)).to be_truthy
      end
    end

    describe 'valid vra except for pids' do
      it 'should pass' do
        expect(@dummy_class.validate_vra(File.open(Rails.root.join('spec', 'fixtures', 'vra_image_with_pids.xml')).read)).to be_truthy
      end
    end
  end
end
