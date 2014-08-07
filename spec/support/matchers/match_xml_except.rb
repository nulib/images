RSpec::Matchers.define :match_xml_except do |*elements|
  # puts elements
  xml_new = elements.shift
  element = elements.first
  match do |xml_orig|
    line_diff = false
    xml_new_array = xml_new.lines.to_a
    xml_orig_array = xml_orig.lines.to_a
    xml_orig_array.each_with_index do |line, count|
      break if line_diff
      next if element && line.include?( element )
      line_diff = line != xml_new_array[ count ]
    end
    !line_diff
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
