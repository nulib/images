module MultiresimageHelper

  #require 'open-uri'

  VRA_SCHEMA = open("http://www.loc.gov/standards/vracore/vra-strict.xsd").read
  # ok solution: we need to have validate_vra for both the multiresimage
  # (which is the VRAimage basically) and the VRAWork model.
  # The validation method can be shared by both classes and to keep
  # everything dry we should put the validate_vra function in a module
  # Soo! What module and where should it live?

  # returns nil is there weren't any validation errors
  def self.validate_vra( vra )

    xsd = Nokogiri::XML::Schema(VRA_SCHEMA)
    doc = Nokogiri::XML( vra )

    invalid = ""
    xsd.validate(doc).each do |error|
      invalid << "Validation error: #{error.message}\n"
    end

    if invalid != ""
      raise invalid
    end
  end
end
