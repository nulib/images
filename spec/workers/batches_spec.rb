require 'rails_helper'
require 'sidekiq/testing'
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
    stdout, stdeerr, status = Open3.capture3("cp #{Rails.root}/spec/fixtures/images/internet.tiff #{Rails.root}/spec/fixtures/batches/valid_job/1234_valid_vra.tiff")

    Sidekiq::Testing.fake!
  end

  #job will do its job -- might belong in controller test
  it "will take a valid job and create Multiresimages" do
    old_count = Multiresimage.all.count
    MultiresimagesBatchWorker.perform_async("valid_job", "user_email@test.com")
    MultiresimagesBatchWorker.drain

    expect(Multiresimage.all.count == (old_count + 1))
    stdout, stdeerr, status = Open3.capture3("cp #{Rails.root}/spec/fixtures/images/internet.tiff #{Rails.root}/spec/fixtures/batches/valid_job/1234_valid_vra.tiff")
  end

  it "will raise an error if there's already an image with the accession munber" do
    #test array of three files contains two files with same accession number, which will cause one error, which means count should only go up by one.
    image_count = Multiresimage.all.count
    vra_count = Vrawork.all.count

    MultiresimagesBatchWorker.perform_async("duplicates", "user_email@test.com")
    MultiresimagesBatchWorker.drain

    expect(image_count + 1).to eql(Multiresimage.all.count)
    expect(vra_count + 1).to eql(Vrawork.all.count)
  end

  it "will send status notifications to user if the job succeeds" do
    ActionMailer::Base.deliveries.clear
    MultiresimagesBatchWorker.perform_async("valid_job", "user_email@test.com")
    MultiresimagesBatchWorker.drain

    expect(ActionMailer::Base.deliveries.last.subject).to eq("The status of your batch of Images records")
    stdout, stdeerr, status = Open3.capture3("cp #{Rails.root}/spec/fixtures/images/internet.tiff #{Rails.root}/spec/fixtures/batches/valid_job/1234_valid_vra.tiff")
    puts "err #{stdeerr}"
    puts "out #{stdout}"
    puts "status #{status}"
  end

end

RSpec.describe MultiresimagesBatchWorker, type: :job do
  it "will send error notifications to admins if the job has errors" do
    ActionMailer::Base.deliveries.clear
    MultiresimagesBatchWorker.perform_async("invalid_vra", "user_email@test.com")
    MultiresimagesBatchWorker.drain

    expect(ActionMailer::Base.deliveries.last.subject).to include("had an error in it")
  end
end
