module MultiresimageHelper

  require 'open-uri'

  VRA_SCHEMA = File.read("#{Rails.root}/app/assets/xml/vra-strict.xsd")

  # returns nil is there weren't any validation errors
  def self.validate_vra( vra )
    doc = Nokogiri::XML( vra )
    xsd = Nokogiri::XML::Schema(VRA_SCHEMA)

    invalid = ""
    xsd.validate(doc).each do |error|
      invalid << "Validation error: #{error.message}\n"
    end

    if invalid != ""
      raise invalid
    end

    true unless invalid
  end


  def self.valid_vra?( vra )
    xsd = Nokogiri::XML::Schema(VRA_SCHEMA)
    doc = Nokogiri::XML( vra )

    xsd.valid?(doc)
  end

end
