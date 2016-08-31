require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe MultiresimagesBatchWorker, type: :job do
  before :each do
    Sidekiq::Worker.clear_all
  end

  it "will enqueue a job" do
    expect(MultiresimagesBatchWorker.jobs.count).to eq(0)
    MultiresimagesBatchWorker.perform_async("1234")
    expect(MultiresimagesBatchWorker.jobs.count).to eq(1)
  end

  it "will take a valid job and create Multiresimages" do
    Sidekiq::Testing.inline!
    old_count = Multiresimage.all.count
    MultiresimagesBatchWorker.perform_async("#{Rails.root}/spec/fixtures/batches/valid_job/1234_valid_vra.tiff")
    MultiresimagesBatchWorker.drain

    expect(Multiresimage.all.count == (old_count + 1))
    Sidekiq::Testing.fake!
  end

  it "will raise an error if there's already an image with the accession number" do
    Sidekiq::Testing.inline!
    MultiresimagesBatchWorker.perform_async("#{Rails.root}/spec/fixtures/batches/valid_job/12345_valid_vra.tiff")
    expect{MultiresimagesBatchWorker.perform_async("#{Rails.root}/spec/fixtures/batches/valid_job/12345_valid_vra.tiff")}.to raise_error(RuntimeError, "Existing image found with this accession number: valid_vra")
    Sidekiq::Testing.fake!
  end
end
