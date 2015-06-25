# run this script with current environment [development, staging, production]:
# bundle exec rails runner -e development lib/remove_image_group_orphans.rb

DILCollection.all.each do |collection|
  puts "Looking for orphans in the collection #{collection.pid}, which contains #{collection.members.find_by_terms(:mods, :relatedItem, :identifier).size} images:"
  # puts collection.object_relations[:has_image]
  collection.members.find_by_terms(:mods, :relatedItem, :identifier).each do |member|
    begin
      image = Multiresimage.find(member.text)
    rescue ActiveFedora::ObjectNotFoundError
      puts "ORPHAN FOUND!: #{member.text}, removing from collection"
      # collection.members.remove_member_by_pid(member.text)
      # collection.save!
    end
  end
end