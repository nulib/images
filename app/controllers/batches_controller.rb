require 'dil/pid_minter'

class BatchesController < ApplicationController
include DIL::PidMinter

  def new

  end

  def create
    puts "  hello!!!   "

    xml_files = Dir.glob( "#{DIL_CONFIG['batch_dir']}/#{params[:job_number]}/*.xml" )
    path = "#{DIL_CONFIG['batch_dir']}/#{params[:job_number]}"

    xml_files.each do |xf|

      pid = mint_pid("dil")
      multiresimage = Multiresimage.new(pid: pid, vra_xml: xf, from_menu: true)
      multiresimage.save
      multiresimage.create_datastreams_and_persist_image_files(path)
    end
    head :ok
  end

end
