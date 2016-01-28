require 'dil/pid_minter'
require 'pry'

class BatchesController < ApplicationController
  include DIL::PidMinter
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

  private

  def validate_job(job_number)
    job_dir = "#{DIL_CONFIG['batch_dir']}/#{job_number}/"
    vra_files = get_vra_files(job_dir)
    image_files = get_image_files(job_dir)
    all_files = vra_files + image_files

    {
      invalid_job_number: validate_job_number(job_number),
      invalid_file_names: invalid_file_names(all_files),
      vra_errors: invalid_vra_files(vra_files), 
      match_errors: find_match_errors(vra_files, image_files) 
    }
  end

  def validate_job_number(job_number)
    job_number if !Dir.exist?("#{DIL_CONFIG['batch_dir']}/#{job_number}/")
  end

  def invalid_file_names(file_list)
    invalid = []
    file_list.each { |file| invalid << file if File.basename(file, ".*").match(/\W/) }
    invalid
  end

  def invalid_vra_files(file_list)
    invalid = []
    file_list.each do |file|
      doc = Nokogiri::XML(File.read(file))
      invalid << file unless XSD.valid?(doc)
    end
    invalid
  end

  def find_match_errors(first_array, second_array)
    first_array_basenames = get_basenames(first_array)
    second_array_basenames = get_basenames(second_array)
    corresponding_file_missing = []

    first_array.each do |item|
      corresponding_file_missing << item unless second_array_basenames.include?(File.basename(item, ".*"))
    end

    second_array.each do |item|
      corresponding_file_missing << item unless first_array_basenames.include?(File.basename(item, ".*"))
    end

    corresponding_file_missing
  end

  def get_vra_files(job_dir)
    Dir.glob(job_dir + "*[!jhove_output].xml", File::FNM_CASEFOLD).sort
  end

  def get_basenames(file_list)
    file_list.map { |file| File.basename(file, ".*") }
  end

  def get_image_files(job_dir)
    Dir.glob(job_dir + "*.tif[f]", File::FNM_CASEFOLD).sort
  end

end
