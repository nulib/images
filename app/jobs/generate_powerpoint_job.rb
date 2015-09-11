class GeneratePowerpointJob < Struct.new(:collection_pid)
  def perform
    DILCollection.find(collection_pid).generate_powerpoint
  end
end