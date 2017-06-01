require 'dil/pid_minter'
require 'rake'

#Important note! Be sure to only pass primitives or simple objects as arguements to the worker, e.g. .perform_async(@project.id).
#These arguements must be serialized and placed #into the Redis queue, and attempting to serialize an entire ActiveRecord object is inefficient and not likely to work.

class MultiresimagesBatchWorker
  include DIL::PidMinter
  include Sidekiq::Worker

  def perform(tiff_file)
    raise 'XML file does not exist' unless File.exist?(tiff_file.ext('xml'))

    nokogiri_doc = get_xml_doc(tiff_file)
    accession_number = get_accession_number(nokogiri_doc)

    raise "Invalid VRA" unless XSD.valid?(nokogiri_doc)
    raise "No accession" if accession_number.empty?
    raise "Existing image found with this accession number: #{accession_number}" if Multiresimage.existing_image?(accession_number)
    ready_xml = TransformXML.prepare_vra_xml(nokogiri_doc.to_xml)
    pid = mint_pid("dil")

    logger.info("Batch worker starting - accession: #{accession_number}, pid: #{pid}")
    m = Multiresimage.create(pid: pid, vra_xml: ready_xml, from_menu: true)
    m.create_datastreams_and_persist_image_files(tiff_file)

    logger.info("Batch worker finished - accession: #{accession_number}, pid: #{pid}")
  end

  def success(job)
    logger.info("Success #{job.inspect} is just fine that's great sweet")
  end

  def error(job, exception)
    logger.error("job #{job} caused error because #{exception}")
  end

  private

  # Take the tiff's file path and find it's associated XML file and convert it into a nokogiri doc
  def get_xml_doc(tiff)
    Nokogiri::XML(File.read(tiff.ext('xml')))
  end


  def get_accession_number(xml)
    xml.xpath("//vra:refid[@source=\"Accession\"]").text
  end

end
