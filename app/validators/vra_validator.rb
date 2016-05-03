module VraValidator

  # returns nil if there weren't any validation errors
  def validate_vra(vra)
    doc = Nokogiri::XML(vra)
    valid = false
    errors = []
    XSD.validate(doc).each do |error|
      errors << "Validation error: #{error.message}\n"
    end

    invalid_errors = errors.reject do |err|
      err.to_s.include?("inu:dil")
    end
    if invalid_errors.empty?
      valid = true
    end
    valid
  end

  def valid_vra?(vra)
    doc = Nokogiri::XML(vra)
    XSD.valid?(doc)
  end
end
