require 'nokogiri'
require 'open-uri'

XSD = Nokogiri::XML::Schema(open("http://www.loc.gov/standards/vracore/vra-strict.xsd").read)