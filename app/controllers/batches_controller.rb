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
      puts "hi i am #{@errors} but i don't know how to respond"
      respond_with @errors, location: batches_path
    else
      user_email = current_user.email
      job_id = MultiresimagesBatchWorker.perform_async(job_number, user_email)
      #sidekiq
      # status = Sidekiq::Status::status(job_id)
      # Sidekiq::Logging.logger.info("status? -> #{status}")
      # Sidekiq::Logging.logger.info("queued? -> #{Sidekiq::Status::queued?(job_id)}")
      # Sidekiq::Status::working?     job_id
      # Sidekiq::Status::complete?    job_id
      # Sidekiq::Status::failed?      job_id
      # Sidekiq::Status::interrupted? job_id

      render :js => "window.location = #{root_path.to_json}"
    end
  end

end
