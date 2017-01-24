module VraValidator

  # returns false if there are validation errors
  def validate_vra(vra)
    valid = false

    valid_errors = get_validation_errors(vra)

    if valid_errors.empty?
      valid = true
    end
    valid
  end

  def valid_vra?(vra)
    doc = Nokogiri::XML(vra)
    XSD.valid?(doc)
  end

  def get_validation_errors(vra)
    doc = Nokogiri::XML(vra)
    errors = []
    XSD.validate(doc).each do |error|
      errors << "Validation error: #{error.message}\n"
    end

    valid_errors = errors.reject do |err|
      err.to_s.include?("inu:dil")
    end

    valid_errors
  end
end
