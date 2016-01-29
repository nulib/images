require 'dil/pid_minter'

class CreateMultiresimagesBatchJob < Struct.new(:job_number, :user_email)
  include DIL::PidMinter

  def perform
    begin
    #this expects the xml files to be all numbers, will have to discuss with jen and nicole
    xml_files = Dir.glob( "#{DIL_CONFIG['batch_dir']}/#{job_number}/*.xml" )
    good_xml_files = xml_files.reject{|x| x.include? "jhove_output.xml" }
    bad_file_storage = []
      good_xml_files.each do |xf|
        xml = nokogiri_doc = Nokogiri::XML(File.read( xf ))
        pid = mint_pid("dil")
        #from_menu = true now has to be re-named.
        multiresimage = Multiresimage.new(pid: pid, vra_xml: xml.to_xml(), from_menu: true)
        multiresimage.save
        #xf ~= ".tif" or ".tiff" -- maybe benchmark faster way of finding this; select on array based on [xf.tif|xf.tiff]?
        tif_path = File.file?(xf.gsub(/.xml/, '.tiff')) ? xf.gsub(/.xml/, '.tiff') : xf.gsub(/.xml/, '.tif')
        result = multiresimage.create_datastreams_and_persist_image_files(tif_path, batch=true)

        bad_file_storage << result unless result.blank?
      end
      
      Delayed::Worker.logger.info("Bad files here: #{bad_file_storage}")
      BatchJobMailer.status_email(user_email, job_number, bad_file_storage).deliver

    rescue StandardError => e
      BatchJobMailer.error_email(job_number, admin_email, exception).deliver
    end
  end

  def success(job)
    Delayed::Worker.logger.info("Success #{job} is just fine that's great sweet")
  end

  def error(job, exception)
    Delayed::Worker.logger.error("job #{job} caused error because #{exception}")
  end
end
