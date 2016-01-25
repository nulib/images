require 'dil/pid_minter'

class BatchesController < ApplicationController
include DIL::PidMinter

  def new
  end

  def create
    xml_files = Dir.glob( "#{DIL_CONFIG['batch_dir']}/#{params[:job_number]}/[\d].xml" )
    xml_files.each do |xf|
      xml = nokogiri_doc = Nokogiri::XML(File.read( xf ))
      pid = mint_pid("dil")
      multiresimage = Multiresimage.new(pid: pid, vra_xml: xml.to_xml(), from_menu: true)
      multiresimage.save
      tif_path = File.file?(xf.gsub(/.xml/, '.tiff')) ? xf.gsub(/.xml/, '.tiff') : xf.gsub(/.xml/, '.tif')
      multiresimage.create_datastreams_and_persist_image_files(tif_path)
    end
    render :create
  end

end
