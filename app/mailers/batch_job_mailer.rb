class BatchJobMailer < ApplicationMailer
  default from: "#{DIL_CONFIG['admin_email']}"

  def status_email(user_email, job_number, bad_file_storage="")
    if bad_file_storage.blank?
      @body = "Hello, all of the files in your batch submission of #{job_number} to Images were turned into Multiresimage records."
    else
      @body = "Hello, your batch submission of #{job_number} to Images contained some errors. The following files didn't turned into Multiresimage records: #{bad_file_storage}."
    end
    mail(to:"#{user_email}, #{DIL_CONFIG['admin_email']}", from: "#{DIL_CONFIG['images_dev_email']}", subject: "The status of your batch of Images records", body: @body)
  end

    def error_email(job_number, exception)
    @body = "Hello, the job #{job_number} failed because #{exception}."
    mail(to:"#{DIL_CONFIG['admin_email']}", from: "#{DIL_CONFIG['images_dev_email']}", subject: "Job #{job_number} didn't make it", body: @body)
  end
end
