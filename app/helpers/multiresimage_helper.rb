module MultiresimageHelper

  # returns nil is there weren't any validation errors
  def self.validate_vra( vra )
    doc = Nokogiri::XML( vra )

    invalid = ""
    XSD.validate(doc).each do |error|
      invalid << "Validation error: #{error.message}\n"
    end

    if invalid != ""
      raise invalid
    end

    true unless invalid
  end


  def self.valid_vra?( vra )
    doc = Nokogiri::XML( vra )

    XSD.valid?(doc)
  end

end
