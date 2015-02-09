require 'nokogiri'
require 'open-uri'

begin
  XSD = Nokogiri::XML::Schema(open("http://www.loc.gov/standards/vracore/vra-strict.xsd").read)
rescue
  # Load up a local XSD if for some reason you can't access LOC
  XSD = Nokogiri::XML::Schema(open("lib/dil/vra-strict.xsd").read)
end