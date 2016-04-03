
class MultiresimagesWithErrorsBatchWorker
  include Sidekiq::Worker

  def perform(job_number, user_email)
    begin
      raise StandardError.new("great")
      BatchJobMailer.status_email(user_email, job_number, bad_file_storage).deliver
    rescue StandardError => e
      puts "in the rescue #{e} and job #{job_number}"
      BatchJobMailer.error_email(job_number, e).deliver
    end
  end

end
