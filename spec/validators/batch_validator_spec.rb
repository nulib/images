require 'rails_helper'
require 'pry'

RSpec.describe BatchValidator do

  class DummyClass
    include BatchValidator
  end

  before(:each) do
    @dummy_class = DummyClass.new
  end

  it "makes #validate_job available" do
    expect(@dummy_class).to respond_to(:validate_job)
  end

  context "batch validation" do
    describe "with an invalid job number" do
      it "should return a string for the job number in the 'invalid_job_number' key" do
        expect( @dummy_class.validate_job('whatever')).to eq({:invalid_job_number=>"whatever", :invalid_file_names=>[], :vra_errors=>[], :match_errors=>[]})
      end
    end

    describe "with invalid vra" do
      it "should return a Hash with an array of values in the 'vra_errors' key" do
        expect( @dummy_class.validate_job('invalid_vra')).to eq({:invalid_job_number=>nil, :invalid_file_names=>[], :vra_errors=>["spec/fixtures/batches/invalid_vra/2345_invalid_vra.xml"], :match_errors=>[]})
      end
    end

    describe "with file match errors" do
      it "should return a Hash with an array of values in the 'match_errors' key" do
        expect( @dummy_class.validate_job('match_errors')).to eq({:invalid_job_number=>nil, :invalid_file_names=>[], :vra_errors=>[], :match_errors=>["spec/fixtures/batches/match_errors/no_matching_image.xml", "spec/fixtures/batches/match_errors/no_matching_vra.tiff"]})
      end
    end

    describe "with invalid file names" do
      it "should return a Hash with an array of values in the 'invalid_file_names' key" do
        expect( @dummy_class.validate_job('invalid_filenames')).to eq({:invalid_job_number=>nil, :invalid_file_names=>["spec/fixtures/batches/invalid_filenames/3456 Invalid Filename.xml", "spec/fixtures/batches/invalid_filenames/3456 Invalid Filename.tiff"], :vra_errors=>[], :match_errors=>[]})
      end
    end
  end

  #   describe "with valid vra" do
  #     xit "should pass" do
  #       expect( @dummy_class.validate_vra( File.open("#{ Rails.root }/spec/fixtures/vra_image_minimal.xml").read )).to be_truthy
  #     end
  #   end

  #   describe "with valid vra" do
  #     it "should pass" do
  #       expect( @dummy_class.validate_vra( File.open("#{ Rails.root }/spec/fixtures/vra_image_minimal_invalid.xml").read )).to be_truthy
  #     end
  #   end
  # end

end