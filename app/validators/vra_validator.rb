module VraValidator

  # returns nil is there weren't any validation errors
  def validate_vra(vra)
    doc = Nokogiri::XML(vra)

    invalid = []
    XSD.validate(doc).each do |error|
      invalid << "Validation error: #{error.message}\n"
    end

    # invalid = errors.reject do |error|
    #   error.include?("inu:dil")
    # end

   #raise StandardError.new("#{invalid}") unless invalid.empty?

    invalid.each do |err|
      next if err =~ /is not a valid value of the list type 'xs:IDREFS'/
      next if err =~ /is not a valid value of the atomic type 'xs:IDREF'/
      next if err =~ /is not a valid value of the atomic type 'xs:ID'/
      raise StandardError.new("#{err}")
    end
  end

  def valid_vra?(vra)
    doc = Nokogiri::XML(vra)
    XSD.valid?(doc)
  end
end
