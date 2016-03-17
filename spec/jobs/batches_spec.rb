require 'rails_helper'
require 'create_multiresimages_with_errors_batch_job'

DIL::Application.load_tasks

RSpec.describe CreateMultiresimagesBatchJob, type: :job do
  before :each do
    Rake::Task["jobs:clear"].invoke
  end

  it "will enqueue a job" do
    expect(Delayed::Job.count).to eq(0)
    Delayed::Job.enqueue CreateMultiresimagesBatchJob.new("12345", "user_email@test.com")

    expect(Delayed::Job.count).to eq(1)
  end

  it "will perform an enqueued job" do
    Delayed::Job.enqueue CreateMultiresimagesBatchJob.new("12345", "user_email@test.com")
    Delayed::Worker.new.work_off

    expect(Delayed::Job.count).to eq(0)
  end

  #job will do its job -- might belong in controller test
  it "will take a valid job and create Multiresimages" do
    Delayed::Job.enqueue CreateMultiresimagesBatchJob.new("valid_job", "user_email@test.com")
    Delayed::Worker.new.work_off
    old_count = Multiresimage.all.count
    expect(Multiresimage.all.count == (old_count + 1))
  end

  it "will send status notifications to user if the job succeeds" do
    Delayed::Job.enqueue CreateMultiresimagesBatchJob.new("12345", "user_email@test.com")
    Delayed::Worker.new.work_off

    expect(ActionMailer::Base.deliveries.last.subject).to eq("The status of your batch of Images records")
  end


end

RSpec.describe CreateMultiresimagesWithErrorsBatchJob, type: :job do
  it "will send error notifications to admins if the job has errors" do

    Delayed::Job.enqueue CreateMultiresimagesWithErrorsBatchJob.new("12345", "user_email@test.com")
    Delayed::Worker.new.work_off

    expect(ActionMailer::Base.deliveries.last.subject).to include("had an error in it")
  end
end
