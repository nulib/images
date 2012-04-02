# Provides some helper methods for indexing compound or non-standard facets
# This file should be moved out of the hydrangea code
# == Methods
# 

module CommonVRAIndexMethods
  # Extracts the first and last names of persons and creates Solr::Field objects with for person_full_name_facet
  #
  # == Returns:
  # An array of Solr::Field objects
  # MAY DELETE THIS IN FAVOR OF AGENT
  def extract_image_creator
    #self.find_by_terms(:vra_image,:agentSet,:agentSet_display).map { |creator| Solr::Field.new({:creator_t=>creator.text}) }
    #self.find_by_terms(:vra_image,:agentSet,:agentSet_display).map { |creator| {:creator_t=>creator.text} }
    creators = {}
    self.find_by_terms(:vra_image,:agentSet,:agentSet_display).each do |creator| 
      ::Solrizer::Extractor.insert_solr_field_value(creators, "creator_t", creator.text) 
    end
    return creators
  end

  #########################
  # Methods for VRA Image #
  #########################

  # Extracts the display field of the titleSet and creates Solr::Field objects with for title_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_image_title_display
 	title_display_array = {}
    self.find_by_terms(:vra_image,:titleSet,:titleSet_display).each do |title_display|
      ::Solrizer::Extractor.insert_solr_field_value(title_display_array, "title_display_t", title_display.text) 
    end
    return title_display_array
  end

  # Extracts the display field of the agentSet and creates Solr::Field objects with for agent_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_image_agent_display
    agent_display_array = {}
    self.find_by_terms(:vra_image,:agentSet,:agentSet_display).each do |agent_display| 
      ::Solrizer::Extractor.insert_solr_field_value(agent_display_array, "agent_display_t", agent_display.text) 
    end
    return agent_display_array
  end

  # Extracts the display field of the dateSet and creates Solr::Field objects with for date_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_image_date_display
    date_display_array = {}
    self.find_by_terms(:vra_image,:dateSet,:dateSet_display).each do |date_display| 
      ::Solrizer::Extractor.insert_solr_field_value(date_display_array, "date_display_t", date_display.text) 
    end
    return date_display_array
  end

  # Extracts the display field of the subjectSet and creates Solr::Field objects with for subject_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_image_subject_display
    subject_display_array = {}
    self.find_by_terms(:vra_image,:subjectSet,:subjectSet_display).each do |subject_display| 
      ::Solrizer::Extractor.insert_solr_field_value(subject_display_array, "subject_display_t", subject_display.text) 
    end
    return subject_display_array
  end

  # Extracts the display field of the Set and creates Solr::Field objects with for description_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_image_description_display
    description_display_array = {}
    self.find_by_terms(:vra_image,:descriptionSet,:descriptionSet_display).each do |description_display| 
      ::Solrizer::Extractor.insert_solr_field_value(description_display_array, "description_display_t", description_display.text) 
    end
    return description_display_array
  end

  # Extracts the relations to Works and creates Solr::Field objects for imageOd and preferred relationships
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_image_relations
    relation_array = {}
    self.find_by_terms(:vra_image,:relationSet,:relation_imageOf, :relation_relids).each do |relation_imageOf| 
      ::Solrizer::Extractor.insert_solr_field_value(relation_array, "relation_imageOf_t", relation_imageOf.text) 
    end
     self.find_by_terms(:vra_image,:relationSet,:relation_preferred, :relation_relids).each do |relation_preferred| 
      ::Solrizer::Extractor.insert_solr_field_value(relation_array, "relation_preferred_t", relation_preferred.text) 
    end
    return relation_array
  end


  #########################
  #  Methods for VRA Work #
  #########################

  # Extracts the display field of the titleSet and creates Solr::Field objects with for title_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_work_title_display
 	title_display_array = {}
    self.find_by_terms(:vra_work,:titleSet,:titleSet_display).each do |title_display|
      ::Solrizer::Extractor.insert_solr_field_value(title_display_array, "title_display_t", title_display.text) 
    end
    return title_display_array
  end

  # Extracts the display field of the agentSet and creates Solr::Field objects with for agent_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_work_agent_display
    agent_display_array = {}
    self.find_by_terms(:vra_work,:agentSet,:agentSet_display).each do |agent_display| 
      ::Solrizer::Extractor.insert_solr_field_value(agent_display_array, "agent_display_t", agent_display.text) 
    end
    return agent_display_array
  end

  # Extracts the display field of the dateSet and creates Solr::Field objects with for date_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_work_date_display
    date_display_array = {}
    self.find_by_terms(:vra_work,:dateSet,:dateSet_display).each do |date_display| 
      ::Solrizer::Extractor.insert_solr_field_value(date_display_array, "date_display_t", date_display.text) 
    end
    return date_display_array
  end

  # Extracts the display field of the subjectSet and creates Solr::Field objects with for subject_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_work_subject_display
    subject_display_array = {}
    self.find_by_terms(:vra_work,:subjectSet,:subjectSet_display).each do |subject_display| 
      ::Solrizer::Extractor.insert_solr_field_value(subject_display_array, "subject_display_t", subject_display.text) 
    end
    return subject_display_array
  end

  # Extracts the display field of the Set and creates Solr::Field objects with for description_display_t
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_work_description_display
    description_display_array = {}
    self.find_by_terms(:vra_work,:descriptionSet,:descriptionSet_display).each do |description_display| 
      ::Solrizer::Extractor.insert_solr_field_value(description_display_array, "description_display_t", description_display.text) 
    end
    return description_display_array
  end

  # Extracts the relations to Images and creates Solr::Field objects for imageOd and preferred relationships
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_work_relations
    relation_array = {}
    self.find_by_terms(:vra_work,:relationSet,:relation_imageIs, :relation_relids).each do |relation_imageIs| 
      ::Solrizer::Extractor.insert_solr_field_value(relation_array, "relation_imageIs_t", relation_imageIs.text) 
    end
     self.find_by_terms(:vra_work,:relationSet,:relation_preferred, :relation_relids).each do |relation_preferred| 
      ::Solrizer::Extractor.insert_solr_field_value(relation_array, "relation_preferred_t", relation_preferred.text) 
    end
    return relation_array
  end

  def extract_work_medium
    #self.find_by_terms(:vra_work,:material_set,:material).map { |material| Solr::Field.new({:medium_t=>material.text}) }
    #self.find_by_terms(:vra_work,:material_set,:material).map { |material| {:medium_t=>material.text} }
    mediums = {}
    self.find_by_terms(:vra_work,:material_set,:material).each do |medium| 
      ::Solrizer::Extractor.insert_solr_field_value(mediums, "medium_t", medium.text) 
    end
    return mediums
  end

  def extract_work_period
    #self.find_by_terms(:vra_work,:period_set,:style_period).map { |period| Solr::Field.new({:topic_tag_facet=>period.text}) }
    #self.find_by_terms(:vra_work,:period_set,:style_period).map { |period| {:topic_tag_facet=>period.text} }
    periods = {}
    self.find_by_terms(:vra_work,:period_set,:style_period).each do |period| 
      ::Solrizer::Extractor.insert_solr_field_value(periods, "topic_tag_facet", period.text) 
    end
    return periods
  end

  def extract_work_person_full_names
    #self.find_by_terms(:vra_work,:agent_set,:display_agent).map { |person| Solr::Field.new({:person_full_name_facet=>person.text}) }
    #self.find_by_terms(:vra_work,:agent_set,:display_agent).map { |person| {:person_full_name_facet=>person.text} }
    person_full_names = {}
    self.find_by_terms(:vra_work,:agent_set,:display_agent).each do |person_full_name| 
      ::Solrizer::Extractor.insert_solr_field_value(person_full_names, "person_full_name_facet", person_full_name.text) 
    end
    return person_full_names
  end


end
