module TransformXML
  include Sidekiq
  #Copied from Menu (github.com/nulib/menu), only the methods required for the batch import flow. JL 02/10/16

  def self.add_empty_work_element( nokogiri_doc )
    remove_work_elements( nokogiri_doc )

    work_element = Nokogiri::XML::Node.new('vra:work', nokogiri_doc)
    begin
      nokogiri_doc.root.add_child(work_element)
    rescue => e
      Sidekiq::Logging.logger.error "TransformXML error: #{e}"
    end
    nokogiri_doc
  end

  private

  def self.remove_work_elements( nokogiri_doc )
    nokogiri_doc.search('//vra:work').remove if nokogiri_doc.at_xpath('//vra:work')
  end
end
