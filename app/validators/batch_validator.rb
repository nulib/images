module BatchValidator
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

  private

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
    puts "names - #{first_array}, #{second_array}"

    first_array_basenames = get_basenames(first_array)
    second_array_basenames = get_basenames(second_array)
    puts "base-names - #{first_array_basenames}, #{second_array_basenames}"
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
    Dir.glob(job_dir + "*.xml", File::FNM_CASEFOLD).sort
  end

  def get_basenames(file_list)
    file_list.map { |file| File.basename(file, ".*") }
  end

  def get_image_files(job_dir)
    Dir.glob(job_dir + "*.tif*", File::FNM_CASEFOLD).sort
  end
end
