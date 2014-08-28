module MultiresimageHelper

  # returns nil is there weren't any validation errors
  def self.validate_vra( vra )
    doc = Nokogiri::XML( vra )

    invalid = []
    XSD.validate(doc).each do |error|
      invalid << "Validation error: #{error.message}\n"
    end

    invalid.each do |error|
      next if error =~ /is not a valid value of the list type 'xs:IDREFS'/
      next if error =~ /is not a valid value of the atomic type 'xs:IDREF'/
      raise error
    end

    true
  end


  def self.valid_vra?( vra )
    doc = Nokogiri::XML( vra )

    XSD.valid?(doc)
  end

end
