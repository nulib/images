require 'sidekiq'

class BatchesController < ApplicationController
  include BatchValidator
  include Sidekiq::Worker

  respond_to :html, :json , :js

  def index
  end

  def new
  end

  def create
    job_number = params.fetch(:job_number) # "123345"
    @errors = validate_job(job_number)

    if @errors[:invalid_job_number].present? || @errors[:vra_errors].any? || @errors[:match_errors].any? || @errors[:invalid_file_names].any?
      respond_with @errors, location: batches_path
    else
      tiff_files = Dir.glob( "#{DIL_CONFIG['batch_dir']}/#{job_number}/*.tif*" )
      tiff_files.each do |t|
        MultiresimagesBatchWorker.perform_async(t.to_s)
      end
      render :js => "window.location = #{root_path.to_json}"
    end
  end
end
