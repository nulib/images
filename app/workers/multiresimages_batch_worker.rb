require 'dil/pid_minter'

#Important note! Be sure to only pass primitives or simple objects as arguements to the worker, e.g. .perform_async(@project.id).
#These arguements must be serialized and placed #into the Redis queue, and attempting to serialize an entire ActiveRecord object is inefficient and not likely to work.

class MultiresimagesBatchWorker
  include DIL::PidMinter
  include Sidekiq::Worker

  sidekiq_options retry: 0

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
    m = Multiresimage.new(pid: pid, vra_xml: ready_xml, from_menu: true)
    m.save

    begin
      # Copy tiff file to tmp directory
      FileUtils.cp(tiff_file, "tmp/#{m.tiff_img_name}")
      m.create_datastreams_and_persist_image_files("tmp/#{m.tiff_img_name}")
    rescue
      m.vraworks.first.delete if m.vraworks.first
      m.delete
      raise "An error occurred in the batch that is not handled explicitly"
    end
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
