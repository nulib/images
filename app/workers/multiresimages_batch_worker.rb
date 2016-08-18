require 'dil/pid_minter'

#Important note! Be sure to only pass primitives or simple objects as arguements to the worker, e.g. .perform_async(@project.id).
#These arguements must be serialized and placed #into the Redis queue, and attempting to serialize an entire ActiveRecord object is inefficient and not likely to work.

class MultiresimagesBatchWorker
  include DIL::PidMinter
  include Sidekiq::Worker

  def perform(job_number, user_email)
    tiff_files = Dir.glob( "#{DIL_CONFIG['batch_dir']}/#{job_number}/*.tif*" )
    tiff_files.each do |t|
      # Regular expression swapping out file extension for .xml
      xml = t.sub /\.[^.]+\z/, ".xml"
      raise "TIFF image does not exist" if !File.exist?(xml)

      doc = Nokogiri::XML(File.read( xml ))
      accession_number = get_accession_number(doc)

      raise "Invalid VRA" unless XSD.valid?(doc)
      raise "No accession" if accession_number.empty?
      raise "Existing image found with this accession number: #{accession_number}" if Multiresimage.existing_image?( accession_number )

      ready_xml = TransformXML.prepare_vra_xml(doc.to_xml)
      m = Multiresimage.create(pid: mint_pid("dil"), vra_xml: ready_xml, from_menu: true)

      begin
        # Copy tiff file to tmp directory
        FileUtils.cp(t, "tmp/#{m.tiff_img_name}")
        m.create_datastreams_and_persist_image_files("tmp/#{m.tiff_img_name}")
      rescue
        m.vraworks.first.delete if m.vraworks.first
        m.delete
        raise "An error occurred in the batch"
      end
    end
  end

  def success(job)
    Sidekiq::Logging.logger.info("Success #{job.inspect} is just fine that's great sweet")
  end

  def error(job, exception)
    Sidekiq::Logging.logger.error("job #{job} caused error because #{exception}")
  end

  private

  def get_accession_number(xml)
    xml.xpath("//vra:refid[@source=\"Accession\"]").text
  end

  def tiff_file_name(accession_number)
    if File.exist?(accession_number + ".tiff")
      accession_number + ".tiff"
    else
      accession_number + ".tif"
    end
  end
end
