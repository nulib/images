module VraValidator

  # returns false if there are validation errors
  def validate_vra(vra)
    get_validation_errors(vra).empty?
  end

  def valid_vra?(vra)
    doc = Nokogiri::XML(vra)
    XSD.valid?(doc)
  end

  def get_validation_errors(vra)
    puts "vra: #{vra}"
    doc = Nokogiri::XML(vra)
    errors = []
    XSD.validate(doc).each do |error|
      errors << "Validation error: #{error.message}\n" unless error.to_s.include?("inu:dil")
    end

    errors
  end
end
