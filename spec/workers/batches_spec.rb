require 'rails_helper'
require 'sidekiq/testing'
require 'multiresimages_with_errors_batch_job'
require 'open3'

Sidekiq::Testing.fake!

RSpec.describe MultiresimagesBatchWorker, type: :job do
  before :each do
    Sidekiq::Worker.clear_all
  end

  it "will enqueue a job" do
    expect(MultiresimagesBatchWorker.jobs.count).to eq(0)
    MultiresimagesBatchWorker.perform_async("12345", "#{DIL_CONFIG['admin_email']}")
    expect(MultiresimagesBatchWorker.jobs.count).to eq(1)

  end

  it "will perform an enqueued job" do
    Sidekiq::Testing.disable!
    MultiresimagesBatchWorker.perform_async("12345", "#{DIL_CONFIG['admin_email']}")
    MultiresimagesBatchWorker.drain

    expect(MultiresimagesBatchWorker.jobs.count).to eq(0)
    Sidekiq::Testing.fake!
  end

  #job will do its job -- might belong in controller test
  it "will take a valid job and create Multiresimages" do
    MultiresimagesBatchWorker.perform_async("valid_job", "user_email@test.com")
    MultiresimagesBatchWorker.drain
    old_count = Multiresimage.all.count
    expect(Multiresimage.all.count == (old_count + 1))
    stdout, stdeerr, status = Open3.capture3("cp #{Rails.root}/spec/fixtures/images/internet.tiff #{Rails.root}/spec/fixtures/batches/valid_job/1234_valid_vra.tiff")

  end

  it "will raise an error if there's already an image with the accession munber" do
    count = Multiresimage.all.count

    #expects the multiresimage to have been created. so do that in setup.

    @xml_from_menu = File.read( "#{ Rails.root }/spec/fixtures/vra_image_sample.xml" )
    MultiresimagesWithErrorsBatchWorker.perform_async("12345", "user_email@test.com")

    expect(count).to eql(Multiresimage.all.count)
  end

  it "will send status notifications to user if the job succeeds" do
    ActionMailer::Base.deliveries.clear
    MultiresimagesBatchWorker.perform_async("valid_job", "user_email@test.com")
    MultiresimagesBatchWorker.drain

    expect(ActionMailer::Base.deliveries.last.subject).to eq("The status of your batch of Images records")
    stdout, stdeerr, status = Open3.capture3("cp #{Rails.root}/spec/fixtures/images/internet.tiff #{Rails.root}/spec/fixtures/batches/valid_job/1234_valid_vra.tiff")
  end

end

RSpec.describe MultiresimagesWithErrorsBatchWorker, type: :job do
  it "will send error notifications to admins if the job has errors" do
    ActionMailer::Base.deliveries.clear
    MultiresimagesWithErrorsBatchWorker.perform_async("12345", "user_email@test.com")
    MultiresimagesWithErrorsBatchWorker.drain

    expect(ActionMailer::Base.deliveries.last.subject).to include("had an error in it")
  end
end
