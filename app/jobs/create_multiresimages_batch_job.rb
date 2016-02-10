require 'dil/pid_minter'

class CreateMultiresimagesBatchJob < Struct.new(:job_number, :user_email)
  include DIL::PidMinter

  def perform
    begin
    xml_files = Dir.glob( "#{DIL_CONFIG['batch_dir']}/#{job_number}/*.xml" )
    good_xml_files = xml_files.reject{|x| x.include? "jhove_output.xml" }
    bad_file_storage = []
      good_xml_files.each do |xf|
        xml = Nokogiri::XML(File.read( xf ))
        ready_xml = TransformXML.add_empty_work_element(xml)
        pid = mint_pid("dil")
        #from_menu = true now has to be re-named.

        multiresimage = Multiresimage.new(pid: pid, vra_xml: ready_xml.to_xml(), from_menu: true)
        multiresimage.save
        test_tif = xf.gsub(/.xml/, '.tiff')
        tif_path = File.file?(test_tif) ? xf.gsub(/.xml/, '.tiff') : xf.gsub(/.xml/, '.tif')
        path = File.dirname(tif_path)
        renamed_tif = File.rename(tif_path, "#{path}/#{multiresimage.tiff_img_name}")
        Delayed::Worker.logger.debug "am i properly renamed? #{renamed_tif}"
        result = multiresimage.create_datastreams_and_persist_image_files(renamed_tif, batch=true)
        bad_file_storage << result unless result == true
      end

      Delayed::Worker.logger.info("Bad files here: #{bad_file_storage}")
      BatchJobMailer.status_email(user_email, job_number, bad_file_storage).deliver

    rescue StandardError => e
      BatchJobMailer.error_email(job_number, e).deliver
    end
  end

  def success(job)
    Delayed::Worker.logger.info("Success #{job.inspect} is just fine that's great sweet")
  end

  def error(job, exception)
    Delayed::Worker.logger.error("job #{job} caused error because #{exception}")
  end
end
