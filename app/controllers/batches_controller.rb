require 'dil/pid_minter'
require 'pry'

class BatchesController < ApplicationController
  include DIL::PidMinter
  include BatchValidator
  respond_to :html, :json , :js

  def index
  end

  def new
  end

  def create
    job_number = params.fetch(:job_number) # "123345"
    @errors = validate_job(job_number)

    if @errors[:invalid_job_number].present? || @errors[:vra_errors].any? || @errors[:match_errors].any? || @errors[:invalid_file_names].any?
      respond_with @errors
    else
      user_email = current_user.email
      Delayed::Job.enqueue CreateMultiresimagesBatchJob.new(job_number, user_email)
      render :js => "window.location = #{root_path.to_json}"
    end
  end

end
