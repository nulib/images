class BatchJobMailer < ApplicationMailer
  default from: "#{DIL_CONFIG['repository_apps_email']}"

  def status_email(user_email, job_number)
    @body = "Hello, all of the files your batch #{job_number} is being processed."
    mail(to:"#{user_email}, #{DIL_CONFIG['admin_email']}", from: "#{DIL_CONFIG['repository_apps_email']}", subject: "The status of your batch of Images records", body: @body)
  end

  def error_email(job_number, exception)
    @body = "Hello, the job #{job_number} contained an error: #{exception}."
    mail(to:"#{DIL_CONFIG['admin_email']}", from: "#{DIL_CONFIG['repository_apps_email']}", subject: "Job #{job_number} had an error in it", body: @body)
  end
end
