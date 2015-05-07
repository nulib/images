require 'nokogiri'
require 'open-uri'

XSD = Nokogiri::XML::Schema(File.open("#{Rails.root}/lib/xsd/vra-strict.xsd"))
