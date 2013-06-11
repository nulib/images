#!/usr/bin/evn ruby

Multiresimage.find_each{|obj|

if !obj.POLICY.content.nil?
  begin
    obj.POLICY.delete
    obj.save
    puts "success: #{obj.pid}"
  rescue Exception
   puts Exception.message
  end
else
  puts "No POLICY ds: #{obj.pid}"
end

}
