#!/usr/bin/evn ruby

# Author: Edgar Garcia
# This notice along with part of this code was lifted from delete_policy_ds.rb as written by Mike Stroming

# BE CAREFUL!!!
# This script reads a file that has a list of Fedora pids (one per line)
# and removes a datastream.
# Make sure to set the config variables!

require 'fileutils'
require 'net/http'

# Configs
folder_path = 'path_to_script'
pids_file_path = "#{folder_path}production_pids_local.txt"
fedora_host = 'localhost'
fedora_port = '8983'
fedora_username = 'username'
fedora_password = 'password'
datastream_name = 'datastream_name_here'

img_ds_missing = []
vra_ds_missing = []
rels_ext_ds_missing = []


begin

  #For each line in file, check the datastreams
  File.readlines(pids_file_path).each do |pid|
    begin
      #remove newline
      pid.gsub!(/\n/,'')

      #trim whitespace
      pid.strip!

      img = Multiresimage.find(pid)

      if img_ds?(img)
        img_ds_missing << pid
      else
        # true - they all exist check for the img
        # get the path to the img then convert it into an actual link and do an http get of the img
        img.datastreams["DELIV-OPS"]

      end
      # Check for the other DC'S
      if !img.datastreams["VRA"].present?
        vra_ds_missing << pid
      end

      if !img.datastreams["RELS-EXT"].present?
        rels_ext_ds_missing << pid
      end

      # Check for missing work.
    end
  end
end

def image_ds?(img)
  img_ds = ["DELIV-OPS", "ARCHV-IMG", "ARCHV-EXIF", "ARCHV-TECHMD", "DELIV-IMG", "DELIV-TECHMD"]

  img_ds.each do |ds|
    if !img.datastreams[ds].present?
      return false
    end
  end
  true
end