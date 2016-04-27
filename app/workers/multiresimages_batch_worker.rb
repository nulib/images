require 'dil/pid_minter'
require 'dil/multiresimage_service'

#Important note! Be sure to only pass primitives or simple objects as arguements to the worker, e.g. .perform_async(@project.id).
#These arguements must be serialized and placed #into the Redis queue, and attempting to serialize an entire ActiveRecord object is inefficient and not likely to work.

class MultiresimagesBatchWorker
  include DIL::PidMinter
  include Sidekiq::Worker
  include DIL::MultiresimageService

  def perform(job_number, user_email)
    begin
      xml_files = Dir.glob( "#{DIL_CONFIG['batch_dir']}/#{job_number}/*.xml" )
      good_xml_files = xml_files.reject{|x| x.include? "jhove_output.xml" }
      bad_file_storage = []
        good_xml_files.each do |xf|
          xml = Nokogiri::XML(File.read( xf ))
          begin
            accession_number = xml.xpath("//refid[@source=\"Accession\"]")
            raise "Existing image found with this accession number" if existing_image?( accession_number.text )
          rescue => e
            Sidekiq::Logging.logger.error("Problem with accession number: #{e}")
          end

          ready_xml = TransformXML.add_empty_work_element(xml)
          pid = mint_pid("dil")
          #from_menu = true now has to be re-named.
          multiresimage = Multiresimage.new(pid: pid, vra_xml: ready_xml.to_xml(), from_menu: true)
          multiresimage.save
          test_tif = xf.gsub(/.xml/, '.tiff')
          tif_path = File.file?(test_tif) ? xf.gsub(/.xml/, '.tiff') : xf.gsub(/.xml/, '.tif')

          tif = File.basename(tif_path)
          FileUtils.mv(tif_path, "tmp/#{tif}")

          File.rename("tmp/#{tif}", "tmp/#{multiresimage.tiff_img_name}")
          result = multiresimage.create_datastreams_and_persist_image_files("tmp/#{multiresimage.tiff_img_name}", batch=true)
          bad_file_storage << result unless result == true
        end

      Sidekiq::Logging.logger.info("Bad files here: #{bad_file_storage}")
      BatchJobMailer.status_email(user_email, job_number, bad_file_storage).deliver

    rescue StandardError => e
      p "an error #{e}"
      BatchJobMailer.error_email(job_number, e).deliver
    end
  end

  def success(job)
    Sidekiq::Logging.logger.info("Success #{job.inspect} is just fine that's great sweet")
  end

  def error(job, exception)
    Sidekiq::Logging.logger.error("job #{job} caused error because #{exception}")
  end
end
