require 'dil/pid_minter'

#Important note! Be sure to only pass primitives or simple objects as arguements to the worker, e.g. .perform_async(@project.id).
#These arguements must be serialized and placed #into the Redis queue, and attempting to serialize an entire ActiveRecord object is inefficient and not likely to work.

class MultiresimagesBatchWorker
  include DIL::PidMinter
  include Sidekiq::Worker

  def perform(tiff_file)
    # Regular expression swapping out file extension for .xml
    xml = tiff_file.sub /\.[^.]+\z/, ".xml"
    raise "XML file does not exist" if !File.exist?(xml)

    doc = Nokogiri::XML(File.read( xml ))
    accession_number = get_accession_number(doc)

    raise "Invalid VRA" unless XSD.valid?(doc)
    raise "No accession" if accession_number.empty?
    raise "Existing image found with this accession number: #{accession_number}" if Multiresimage.existing_image?(accession_number)
    ready_xml = TransformXML.prepare_vra_xml(doc.to_xml)
    pid = mint_pid("dil")

    begin
      logger.info("Batch worker starting - accession: #{accession_number}, pid: #{pid}")
      m = nil
      m = Multiresimage.new(pid: pid, vra_xml: ready_xml, from_menu: true)
      m.save
      # Copy tiff file to tmp directory
      tmp_tiff_path = "tmp/#{m.tiff_img_name}"
      tiff_derivative_path = m.tiff_derivative_path
      FileUtils.cp(tiff_file, tmp_tiff_path)
      m.create_datastreams_and_persist_image_files(tmp_tiff_path)
    rescue StandardError => e
      unless m.nil? || m.destroyed?
        m.delete
      end

      # check that everything was successfully cleaned up
      if Multiresimage.existing_image?(accession_number)
        logger.error("Unable to cleanup all records. Existing image or work still found in Images with accession number: #{accession_number}")
      end
      raise "Had a problem saving #{tiff_file}: #{e.message}"
    ensure
      if File.exist?(tmp_tiff_path)
        logger.info("Attempting to cleanup temp tiff file at: #{tmp_tiff_path}")
        File.unlink(tmp_tiff_path)
      end
      File.unlink(tiff_derivative_path) if File.exist?(tiff_derivative_path)
    end
    logger.info("Batch worker finished - accession: #{accession_number}, pid: #{pid}")
  end

  def success(job)
    logger.info("Success #{job.inspect} is just fine that's great sweet")
  end

  def error(job, exception)
    logger.error("job #{job} caused error because #{exception}")
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
