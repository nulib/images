class BatchJobMailer < ApplicationMailer
  default from: "images@northwestern.edu"

  def status_email(user_email, job_number, bad_file_storage="")
    if bad_file_storage.blank?
      @body = "Hello, all of the files in your batch submission of #{job_number} to Images were turned into Multiresimage records."
    else
      @body = "Hello, your batch submission of #{job_number} to Images contained some errors. The following files didn't turned into Multiresimage records: #{bad_file_storage}."
    end
    mail(to:"#{user_email},jennifer.lindner@northwestern.edu", from: "Brendan-Quinn@northwestern.edu", subject: "The status of your batch of Images records", body: @body)
  end

    def error_email(job_number, admin_email, exception)
    @body = "Hello, the job #{job_number} failed."
    mail(to:"#{admin_email},jennifer.lindner@northwestern.edu", from: "Brendan-Quinn@northwestern.edu", subject: "Job #{job_numbers} didn't make it", body: @body)
  end
end
