require 'dil/pid_minter'

class CreateMultiresimagesWithErrorsBatchJob < Struct.new(:job_number, :user_email)
  include DIL::PidMinter

  def perform
    begin
      raise StandardError.new("great")
      BatchJobMailer.status_email(user_email, job_number, bad_file_storage).deliver
    rescue StandardError => e
      puts "in the rescue #{e} and job #{job_number}"
      BatchJobMailer.error_email(job_number, e).deliver
    end
  end

  def success(job)
    Delayed::Worker.logger.info("Success #{job} is just fine that's great sweet")
  end

  def error(job, exception)
    Delayed::Worker.logger.error("job #{job} caused error because #{exception}")
  end
end
