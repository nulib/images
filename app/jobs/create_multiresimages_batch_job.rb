class CreateMultiresimagesBatchJob < Struct.new(:job_number)
  def perform
    #this expects the xml files to be all numbers, will have to discuss with jen and nicole
    xml_files = Dir.glob( "#{DIL_CONFIG['batch_dir']}/#{job_number}/[!jhove_output].xml" )
    xml_files.each do |xf|
      xml = nokogiri_doc = Nokogiri::XML(File.read( xf ))
      pid = mint_pid("dil")
      #from_menu = true now has to be re-named.
      multiresimage = Multiresimage.new(pid: pid, vra_xml: xml.to_xml(), from_menu: true)
      multiresimage.save
      #xf ~= ".tif" or ".tiff" -- maybe benchmark faster way of finding this; select on array based on [xf.tif|xf.tiff]?
      tif_path = File.file?(xf.gsub(/.xml/, '.tiff')) ? xf.gsub(/.xml/, '.tiff') : xf.gsub(/.xml/, '.tif')
      multiresimage.create_datastreams_and_persist_image_files(tif_path, batch=true)
    end
  end
end
