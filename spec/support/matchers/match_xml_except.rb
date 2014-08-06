RSpec::Matchers.define :match_xml_except do |*elements|
  # puts elements
  xml_new = elements.shift
  element = elements.first
  match do |xml_orig|
    no_match = 0
    xml_new_array = xml_new.lines.to_a
    xml_orig_array = xml_orig.lines.to_a
    xml_orig_array.each_with_index do |line, count|
      break if no_match > 0
      next if element && line.include?( element )
      no_match += 1 unless line == xml_new_array[ count ]
    end
    if no_match == 0
      true
    else
      false
    end
  end

    # Optional failure messages
  failure_message_for_should do |actual|
    "expected XML to match"
  end

  failure_message_for_should_not do |actual|
    "expected XML not to match"
  end

  # Optional method description
  description do
    "checks to see if two XML strings match, except for the supplied element"
  end
end
