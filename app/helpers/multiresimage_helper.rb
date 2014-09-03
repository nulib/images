module MultiresimageHelper

  # returns nil is there weren't any validation errors
  def self.validate_vra( vra )
    doc = Nokogiri::XML( vra )

    invalid = []
    XSD.validate(doc).each do |error|
      invalid << "Validation error: #{error.message}\n"
    end

    invalid.each do |err|
      next if err =~ /is not a valid value of the list type 'xs:IDREFS'/
      next if err =~ /is not a valid value of the atomic type 'xs:IDREF'/
      next if err =~ /is not a valid value of the atomic type 'xs:ID'/
      raise
    end

    true
  end


  def self.valid_vra?( vra )
    doc = Nokogiri::XML( vra )

    XSD.valid?(doc)
  end

end
