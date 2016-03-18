class VRADatastream < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(:path=>"vra", :xmlns=>"http://www.vraweb.org/vracore4.htm", :schema=>"http://www.loc.gov/standards/vracore/vra.xsd" )

    # titleSet OM definition
    t.titleSet_ref(:path=>"titleSet", :label=>"Titles", :index_as=>[:searchable]) {
      t.titleSet_display(:path=>"display", :label=>"display", :index_as=>[:searchable])
      t.title(:path=>"title", :label=>"title", :index_as=>[:searchable, :displayable])
      t.title_pref(:path=>"title", :attributes=>{:pref=>"true"}, :index_as=>[:searchable])
      t.title_altSet_display(:path=>"title", :attributes=>{:pref=>"false"}, :index_as=>[:searchable, :displayable])
    }

    # agentSet OM definitions
    t.agentSet_ref(:path=>"agentSet", :label=>"Agents", :index_as=>[:searchable]) {
      t.agentSet_display(:path=>"display", :index_as=>[:searchable])
      t.agent(:ref=>[:agent_ref], :index_as=>[:searchable])
    }

    t.agent_ref(:path=>"agent", :index_as=>[:searchable]){
      t.name {
        t.name_content(:path=>'text()', :index_as=>[:searchable])
        t.name_vocab(:path=>{:attribute =>"vocab"}, :index_as=>[:searchable])
        t.name_refid(:path=>{:attribute =>"refid"}, :index_as=>[:searchable])
        t.name_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
      }
      t.dates {
        t.life(:path=>{:attribute =>"life"}, :index_as=>[:searchable])
        t.earliestDate(:index_as=>[:searchable])
        t.latestDate(:index_as=>[:searchable])
      }
      t.role(:index_as=>[:searchable])
      t.attribution(:index_as=>[:searchable])
      t.culture(:index_as=>[:searchable])
    }

    # descriptionSet OM definition
    t.descriptionSet_ref(:path=>"descriptionSet", :label=>"Descriptions", :index_as=>[:searchable]) {
      t.descriptionSet_display(:path=>"display", :label=>"display description", :index_as=>[:searchable])
      t.description(:path=>"description", :label=>"description", :index_as=>[:searchable])
    }

    # inscriptionSet_ref OM definition
    t.inscriptionSet_ref(:path=>"inscriptionSet", :label=>"Inscriptions", :index_as=>[:searchable]) {
      t.inscriptionSet_display(:path=>"display", :index_as=>[:searchable])
      t.inscription(:path=>"inscription", :label=>"inscription", :index_as=>[:searchable])
    }

    # dateSet OM definition
    t.dateSet_ref(:path=>"dateSet", :label=>"Dates", :index_as=>[:searchable]) {
      t.dateSet_display(:path=>"display", :index_as=>[:searchable])
      t.date{
        t.date_content(:path=>'text()', :index_as=>[:searchable])
        t.date_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
        t.earliestDate
        t.latestDate
      }
    }

    # stylePeriod OM definition
    t.stylePeriodSet_ref(:path=>"stylePeriodSet", :label=>"Periods", :index_as=>[:searchable]) {
      t.stylePeriodSet_display(:path=>"display", :index_as=>[:searchable])
      t.stylePeriod {
        t.stylePeriod_content(:path=>'text()', :index_as=>[:searchable])
        t.stylePeriod_vocab(:path=>{:attribute =>"vocab"}, :index_as=>[:searchable])
        t.stylePeriod_refid(:path=>{:attribute =>"refid"}, :index_as=>[:searchable])
      }
    }

    # editionSet OM definition
    t.editionSet_ref(:path=>"editionSet", :label=>"Edition", :index_as=>[:searchable]) {
      t.editionSet_display(:path=>"display", :label=>"display edition", :index_as=>[:searchable])
      t.edition(:path=>"edition", :label=>"edition", :index_as=>[:searchable])
    }

    # rightsSet OM definition
    t.rightsSet_ref(:path=>"rightsSet", :label=>"Rights", :index_as=>[:searchable]) {
      t.rightsSet_display(:path=>"display", :index_as=>[:searchable])
      t.rights {
        t.rights_content(:path=>'text()', :index_as=>[:searchable])
        t.rights_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
      }
    }

    # materialSet OM definition
    t.materialSet_ref(:path=>"materialSet", :label=>"Materials", :index_as=>[:searchable]) {
      t.materialSet_display(:path=>"display", :index_as=>[:searchable])
      t.material
    }

    # culturalContextSet OM definition
    t.culturalContextSet_ref(:path=>"culturalContextSet", :label=>"Cultural Contexts", :index_as=>[:searchable]) {
      t.culturalContextSet_display(:path=>"display", :index_as=>[:searchable])
      t.culturalContext {
        t.culturalContext_content(:path=>'text()', :index_as=>[:searchable])
        t.culturalContext_refid(:path=>{:attribute =>"refid"}, :index_as=>[:searchable])
        t.culturalContext_vocab(:path=>{:attribute =>"vocab"}, :index_as=>[:searchable])
      }
    }

    # measurementsSet OM definition
    t.measurementsSet_ref(:path=>"measurementsSet", :label=>"Measurements", :index_as=>[:searchable]) {
      t.measurementsSet_display(:path=>"display", :index_as=>[:searchable])
      t.measurements {
        t.measurements_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
        t.measurements_unit(:path=>{:attribute =>"unit"}, :index_as=>[:searchable])
        t.measurements_extent(:path=>{:attribute =>"extent"}, :index_as=>[:searchable])
      }
    }

    # techniqueSet OM definition
    t.techniqueSet_ref(:path=>"techniqueSet", :label=>"Technique", :index_as=>[:searchable]) {
      t.techniqueSet_display(:path=>"display", :index_as=>[:searchable])
      t.technique {
        t.technique_content(:path=>'text()', :index_as=>[:searchable])
        t.technique_refid(:path=>{:attribute =>"refid"}, :index_as=>[:searchable])
        t.technique_vocab(:path=>{:attribute =>"vocab"}, :index_as=>[:searchable])
      }
    }

    # worktypeSet OM definition
    t.worktypeSet_ref(:path=>"worktypeSet", :label=>"Work Type", :index_as=>[:searchable]) {
      t.worktypeSet_display(:path=>"display", :index_as=>[:searchable])
      t.worktype {
        t.worktype_content(:path=>'text()', :index_as=>[:searchable])
        t.worktype_refid(:path=>{:attribute =>"refid"}, :index_as=>[:searchable])
        t.worktype_vocab(:path=>{:attribute =>"vocab"}, :index_as=>[:searchable])
      }
    }

    # locationSet OM definitions
    t.locationSet_ref(:path=>"locationSet", :label=>"Locations", :index_as=>[:searchable]) {
      t.locationSet_display(:path=>"display", :index_as=>[:searchable])
      t.location(:ref=>[:location_ref], :index_as=>[:searchable])
    }

    t.location_ref(:path=>"location", :index_as=>[:searchable]){
      t.location_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
      t.name {
        t.name_content(:path=>'text()', :index_as=>[:searchable])
        t.name_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
        t.name_vocab(:path=>{:attribute =>"vocab"}, :index_as=>[:searchable])
        t.name_refid(:path=>{:attribute =>"refid"}, :index_as=>[:searchable])
      }
      t.refid {
        t.refid_content(:path=>'text()', :index_as=>[:searchable])
        t.name_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
      }
    }

    # sourceSet OM definitions
    t.sourceSet_ref(:path=>"sourceSet", :label=>"Sources", :index_as=>[:searchable]) {
      t.sourceSet_display(:path=>"display", :index_as=>[:searchable])
      t.source(:ref=>[:source_ref], :index_as=>[:searchable])
    }
    t.source_ref(:path=>"source", :index_as=>[:searchable]){
      t.name {
        t.name_content(:path=>'text()', :index_as=>[:searchable])
        t.name_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
      }
      t.refid {
        t.refid_content(:path=>'text()', :index_as=>[:searchable])
        t.name_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
      }
    }
    t.textrefSet_ref(:path=>"textrefSet", :label=>"Text References", :index_as=>[:searchable]) {
      t.textrefSet_display(:path=>"display", :index_as=>[:searchable])
      t.textref(:ref=>[:textref_ref], :index_as=>[:searchable])
    }

    t.textref_ref(:path=>"textref", :index_as=>[:searchable]){
      t.name {
        t.name_content(:path=>'text()', :index_as=>[:searchable])
        t.name_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
      }
      t.refid {
        t.refid_content(:path=>'text()', :index_as=>[:searchable])
        t.name_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
      }
    }

    # subjectSet OM definition
    t.subjectSet_ref(:path=>"subjectSet", :label=>"Subjects", :index_as=>[:searchable]) {
      t.subjectSet_display(:path=>"display")
      t.subject {
        t.term {
          t.subject_term_content(:path=>'text()', :index_as=>[:searchable])
          t.subject_term_type(:path=>{:attribute =>"type"}, :index_as=>[:searchable])
          t.subject_term_vocab(:path=>{:attribute =>"vocab"}, :index_as=>[:searchable])
          t.subject_term_refid(:path=>{:attribute =>"refid"}, :index_as=>[:searchable])
        }
      }
    }

    # relationSet OM definitions
    t.relationSet_ref(:path=>"relationSet", :index_as=>[:searchable]) {
      t.relationSet_display(:path=>"display", :label=>"Relation", :index_as=>[:searchable])

      t.imageOf_others(:path=>"relation", :attributes=>{:pref=>:none, :type=>"imageOf"}, :index_as=>[:searchable]) do
        t.relation_relids(:path=>{:attribute=>"relids"}, :index_as=>[:searchable])
      end

      t.imageOf_preferred(:path=>"relation", :attributes=>{:pref=>"true", :type=>"imageOf"}, :label=>"Preferred Work", :index_as=>[:searchable]) {
        t.relation_type(:path=>{:attribute=>"type"}, :index_as=>[:searchable])
        t.relation_relids(:path=>{:attribute=>"relids"}, :index_as=>[:searchable])
        #t.relation_href(:path=>{:attribute=>"href"})
      }

      t.imageOf(:path=>"relation", :attributes=>{:type=>"imageOf"}, :label=>"Image of Work", :index_as=>[:searchable]) {
        t.relation_type(:path=>{:attribute=>"type"}, :index_as=>[:searchable])
        t.relation_relids(:path=>{:attribute=>"relids"}, :index_as=>[:searchable])
        #t.relation_href(:path=>{:attribute=>"href"})
      }

      t.imageIs_preferred(:path=>"relation", :attributes=>{:pref=>"true", :type=>"imageIs"}, :label=>"Preferred Image", :index_as=>[:searchable]) {
        t.relation_type(:path=>{:attribute=>"type"}, :index_as=>[:searchable])
        t.relation_relids(:path=>{:attribute=>"relids"}, :index_as=>[:searchable])
        #t.relation_href(:path=>{:attribute=>"href"})
      }

      t.imageIs(:path=>"relation", :attributes=>{:type=>"imageIs"}, :label=>"Image of Work", :index_as=>[:searchable]) {
        t.relation_type(:path=>{:attribute=>"type"}, :index_as=>[:searchable])
        t.relation_relids(:path=>{:attribute=>"relids"}, :index_as=>[:searchable])
        #t.relation_href(:path=>{:attribute=>"href"})
      }

      t.relation(:path=>"relation", :label=>"Relation", :index_as=>[:searchable]) {
        t.relation_type(:path=>{:attribute=>"type"}, :index_as=>[:searchable])
        t.relation_relids(:path=>{:attribute=>"relids"}, :index_as=>[:searchable])
        #t.relation_href(:path=>{:attribute=>"href"})
      }

      t.relation_preferred(:path=>"relation", :attritubes=>{:pref=>"true"}, :label=>"Pref Relation", :index_as=>[:searchable]) {
        t.relation_type(:path=>{:attribute=>"type"}, :index_as=>[:searchable])
        t.relation_relids(:path=>{:attribute=>"relids"}, :index_as=>[:searchable])
        #t.relation_href(:path=>{:attribute=>"href"})
      }
    }

    # VRA Image OM definition
    t.image(:path=>"image", :label=>"image", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
      t.agentSet(:ref=>[:agentSet_ref])
      t.titleSet(:ref=>[:titleSet_ref])
      t.descriptionSet(:ref=>[:descriptionSet_ref])
      t.inscriptionSet(:ref=>[:inscriptionSet_ref])
      t.dateSet(:ref=>[:dateSet_ref])
      t.stylePeriodSet(:ref=>[:stylePeriodSet_ref])
      t.culturalContextSet(:ref=>[:culturalContextSet_ref])
      t.materialSet(:ref=>[:materialSet_ref])
      t.measurementsSet(:ref=>[:measurementsSet_ref])
      t.techniqueSet(:ref=>[:techniqueSet_ref])
      t.worktypeSet(:ref=>[:worktypeSet_ref])
      t.locationSet(:ref=>[:locationSet_ref])
      t.sourceSet(:ref=>[:sourceSet_ref])
      t.subjectSet(:ref=>[:subjectSet_ref])
      t.relationSet(:ref=>[:relationSet_ref])
      t.editionSet(:ref=>[:editionSet_ref])
      t.rightsSet(:ref=>[:rightsSet_ref])
      t.textrefSet(:ref=>[:textrefSet_ref])
    }

    # VRA Work OM definition
    t.work(:path=>"work", :label=>"work", :xmlns=>"http://www.vraweb.org/vracore4.htm") {
      t.agentSet(:ref=>[:agentSet_ref])
      t.titleSet(:ref=>[:titleSet_ref])
      t.descriptionSet(:ref=>[:descriptionSet_ref])
      t.inscriptionSet(:ref=>[:inscriptionSet_ref])
      t.dateSet(:ref=>[:dateSet_ref])
      t.stylePeriodSet(:ref=>[:stylePeriodSet_ref])
      t.culturalContextSet(:ref=>[:culturalContextSet_ref])
      t.materialSet(:ref=>[:materialSet_ref])
      t.measurementsSet(:ref=>[:measurementsSet_ref])
      t.techniqueSet(:ref=>[:techniqueSet_ref])
      t.worktypeSet(:ref=>[:worktypeSet_ref])
      t.locationSet(:ref=>[:locationSet_ref])
      t.sourceSet(:ref=>[:sourceSet_ref])
      t.subjectSet(:ref=>[:subjectSet_ref])
      t.relationSet(:ref=>[:relationSet_ref])
      t.editionSet(:ref=>[:editionSet_ref])
      t.rightsSet(:ref=>[:rightsSet_ref])
      t.textrefSet(:ref=>[:textrefSet_ref])
    }

    t.agentSet_display(:proxy=>[:image, :agentSet, :agentSet_display])
    t.titleSet_display(:proxy=>[:image, :titleSet, :titleSet_display])
    t.title_altSet_display(:proxy=>[:image, :titleSet, :title_altSet_display])
    t.descriptionSet_display(:proxy=>[:image, :descriptionSet, :descriptionSet_display])
    t.inscriptionSet_display(:proxy=>[:image, :inscriptionSet, :inscriptionSet_display])
    t.dateSet_display(:proxy=>[:image, :dateSet, :dateSet_display])
    t.subjectSet_display(:proxy=>[:image, :subjectSet, :subjectSet_display])
    t.locationSet_display(:proxy=>[:image, :locationSet, :locationSet_display])
    t.materialSet_display(:proxy=>[:image, :materialSet, :materialSet_display])
    t.measurementsSet_display(:proxy=>[:image, :measurementsSet, :measurementsSet_display])
    t.stylePeriodSet_display(:proxy=>[:image, :stylePeriodSet, :stylePeriodSet_display])
    t.inscriptionSet_display(:proxy=>[:image, :inscriptionSet, :inscriptionSet_display])
    t.worktypeSet_display(:proxy=>[:image, :worktypeSet, :worktypeSet_display])
    t.culturalContextSet_display(:proxy=>[:image, :culturalContextSet, :culturalContextSet_display])
    t.techniqueSet_display(:proxy=>[:image, :techniqueSet, :techniqueSet_display])
    t.sourceSet_display(:proxy=>[:image, :sourceSet, :sourceSet_display])
    t.editionSet_display(:proxy=>[:image, :editionSet, :editionSet_display])
    t.rightsSet_display(:proxy=>[:image, :rightsSet, :rightsSet_display])
    t.relationSet_display(:proxy=>[:image, :relationSet, :relationSet_display])
    t.textrefSet_display(:proxy=>[:image, :textrefSet, :textrefSet_display])


    t.agentSet_display_work(:proxy=>[:work, :agentSet, :agentSet_display])
    t.titleSet_display_work(:proxy=>[:work, :titleSet, :titleSet_display])
    t.title_altSet_display_work(:proxy=>[:work, :titleSet, :title_altSet_display])
    t.descriptionSet_display_work(:proxy=>[:work, :descriptionSet, :descriptionSet_display])
    t.inscriptionSet_display_work(:proxy=>[:work, :inscriptionSet, :inscriptionSet_display])
    t.dateSet_display_work(:proxy=>[:work, :dateSet, :dateSet_display])
    t.subjectSet_display_work(:proxy=>[:work, :subjectSet, :subjectSet_display])
    t.locationSet_display_work(:proxy=>[:work, :locationSet, :locationSet_display])
    t.materialSet_display_work(:proxy=>[:work, :materialSet, :materialSet_display])
    t.measurementsSet_display_work(:proxy=>[:work, :measurementsSet, :measurementsSet_display])
    t.stylePeriodSet_display_work(:proxy=>[:work, :stylePeriodSet, :stylePeriodSet_display])
    t.inscriptionSet_display_work(:proxy=>[:work, :inscriptionSet, :inscriptionSet_display])
    t.worktypeSet_display_work(:proxy=>[:work, :worktypeSet, :worktypeSet_display])
    t.culturalContextSet_display_work(:proxy=>[:work, :culturalContextSet, :culturalContextSet_display])
    t.techniqueSet_display_work(:proxy=>[:work, :techniqueSet, :techniqueSet_display])
    t.sourceSet_display_work(:proxy=>[:work, :sourceSet, :sourceSet_display])
    t.editionSet_display_work(:proxy=>[:work, :editionSet, :editionSet_display])
    t.rightsSet_display_work(:proxy=>[:work, :rightsSet, :rightsSet_display])
    t.relationSet_display_work(:proxy=>[:work, :relationSet, :relationSet_display])
    t.textrefSet_display_work(:proxy=>[:work, :textrefSet, :textrefSet_display])
    #t.title(:proxy=>[:work, :titleSet, :titleSet_display])
  end


  # Adds VRA image record to VRA
  def add_image(image_node)
    nodeset = self.find_by_terms(:vra)
    image_node.first.add_namespace_definition("vra","http://www.vraweb.org/vracore4.htm")
    nodeset.first.add_child(image_node)
    self.content = self.ng_xml.to_s
    return nodeset
  end

  # DEPRECATION WARNING: In active-fedora 8 the solr fields created by
  # VRADatastream will be prefixed with "vra__".  If you want to maintain
  # the existing behavior, you must override VRADatastream.#prefix to return an empty string.
  def prefix
    ""
  end

  # Generates new VRA datastream
  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.vra("xmlns"=>"http://www.vraweb.org/vracore4.htm", "xmlns:vra"=>"http://www.vraweb.org/vracore4.htm",
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation"=>"http://www.loc.gov/standards/vracore/vra.xsd") {

        xml.parent.namespace = xml.parent.namespace_definitions.find{|ns|ns.prefix=="vra"}
        xml['vra'].image(:refid=>""){
          xml['vra'].agentSet {
            xml.display_
            xml.agent {
              xml.name
              xml.attribution
            }
          }

          xml['vra'].culturalContextSet {
            xml.display_
          }

          xml['vra'].dateSet {
            xml.display_ {
              xml.date{
                xml.dateContent
                xml.dateType(:type=>"")
                xml.earliestDate
                xml.latestDate
              }
            }
          }

          xml['vra'].descriptionSet {
            xml.display_
            xml.description
          }

          xml['vra'].editionSet {
            xml.display_
            xml.edition
          }

          xml['vra'].inscriptionSet {
            xml.display_
            xml.inscription
          }


          xml['vra'].relationSet {
            xml.display_
            xml.relation(:type=>"imageOf", :pref=>"true", :label=>"Work")
          }

          xml['vra'].rightsSet {
            xml.display_
            xml.rights
          }

          xml['vra'].stylePeriodSet {
            xml.display_
            xml.stylePeriod
          }

          xml['vra'].subjectSet {
            xml.display_
            xml.subject
          }

          xml['vra'].techniqueSet {
            xml.display_
            xml.technique
          }

          xml['vra'].titleSet {
            xml.display_
            xml.title(:pref=>"true")
            xml.title(:pref=>"false")
          }

          xml['vra'].worktypeSet {
            xml.display_
            xml.worktype
          }

          xml['vra'].textrefSet {
            xml.display_
            xml.textref
          }
        }
      }
    end
    return builder.doc
  end


  # Generates VRA Image
  def self.image_template item
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.image(:xmlns=>"http://www.vraweb.org/vracore4.htm") {
        xml.titleSet {
          xml.display
          xml.title(:pref=>"true")
          xml.title(:pref=>"false")
        }

        xml.agentSet {
          xml.display
        }

        xml.relationSet {
          xml.display
          xml.relation(:type=>"imageOf", :pref=>"true", :label=>"Work")
        }
      }
    end
    return builder.doc
  end


  # Inserts a new vra_image
  def insert_image(parms)
    node = Hydra::VRAImage.image_template({:title => parms[:title]}).root()
    nodeset = self.find_by_terms(:vra)

    unless nodeset.nil?
      self.ng_xml.root.add_child(node)
      self.content = self.ng_xml.to_s
    end

    return node
  end


  def self.valid_child_types
    ["data", "supporting file", "profile", "lorem ipsum", "dolor"]
  end


  # Extract all the VRA sets for this datastream to the provided solr_doc
  def add_vra_description_to_solrdoc(solr_doc)

    # This string will be used to append all the values we're merging into the solr_doc into
    # one field in the solr_doc, search_field_t.  This field is then used for searching.
    # Or use array with set names and Ruby send() to invoke the method where the method name is a symbol
    search_field = ""

    #This can be refactored, there's some stuff that is repeated a bunch of times
    #Can combine search_field and solr_doc merge into a method, and that method calls each

    #Store the output of the extract methods in a Hash (key is the solr field name, value is a String or Array
    #of Strings for the field values
    hashSet = extract_agentSet

    #Append to the search_field
    search_field << extract_values_for_search_field(hashSet)

    # Merge the hashSet into the solr_doc
    # The block is to tell Ruby what to do when it encounters a duplicate key during hash merging.
    # We add the work's solr fields after the image solr fields are already there, so we tell Ruby
    # to add indexes to the array from newval to oldval (example: ["1", "2"] and ["3", "4"] are then ["1", "2", "3", "4"]
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #Repeat for each set

    #titleSet
    hashSet = extract_titleSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #descriptionSet
    hashSet = extract_descriptionSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #inscriptionSet
    hashSet = extract_inscriptionSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #dateSet
    hashSet = extract_dateSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #stylePeriodSet
    hashSet = extract_stylePeriodSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #culturalContextSet
    hashSet = extract_culturalContextSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #materialSet
    hashSet = extract_materialSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #measurementsSet
    hashSet = extract_measurementsSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #techniqueSet
    hashSet = extract_techniqueSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #worktypeSet
    hashSet = extract_worktypeSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #locationSet
    hashSet = extract_locationSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #editionSet
    hashSet = extract_editionSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval| oldval | newval }

    #rightsSet
    hashSet = extract_rightsSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval| oldval | newval }

    #sourceSet
    hashSet = extract_sourceSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #subjectSet
    hashSet = extract_subjectSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }

    #textrefSet
    hashSet = extract_textrefSet
    search_field << extract_values_for_search_field(hashSet)
    solr_doc = solr_doc.merge(hashSet) { |field_name, oldval, newval|  oldval | newval }


    # The block is to tell Ruby what to do when it encounters a duplicate key during hash merging.
    # We add the work's solr fields after the image solr fields are already there, so we tell Ruby
    # to append the new string to the old
    search_field_hash = Hash["search_field_tesim" => search_field]
    solr_doc = solr_doc.merge(search_field_hash) { |field_name, oldval, newval | oldval << newval }

    return solr_doc
  end

  # The hash has the solr field names and solr field values
  # This method just gets the value from each hash and appends it to a string.
  # The string is returned.
  def extract_values_for_search_field(hashSet)
    values = ""
    hashSet.each_pair do |k,v|
      if v.present? and v.kind_of?(Array)
        v.each do |value|
          values << "#{value} "
        end

      #convert String to a String Array
      elsif v.present?
        values << "#{v} "
      end
    end
    return values
  end


  def add_sort_fields(solr_doc)

    ## Add a field for sorting title
    if (!self.find_by_terms('//vra:titleSet/vra:title[@pref="true"]').nil? and !self.find_by_terms('//vra:titleSet/vra:title[@pref="true"]').empty?)
      title_pref_node = self.find_by_terms('//vra:titleSet/vra:title[@pref="true"]').first

      if (!title_pref_node.nil?)
        title_hash = Hash["title_dil" => title_pref_node.text]
        solr_doc = solr_doc.merge(title_hash)
      end
    elsif
      if (!self.find_by_terms('//vra:titleSet').nil? and !self.find_by_terms('//vra:titleSet').empty?)
        titleset_display_node = self.find_by_terms('//vra:titleSet').first.xpath('./vra:display')
        if (!titleset_display_node.nil?)
          title_hash = Hash["title_dil" => titleset_display_node.text]
          solr_doc = solr_doc.merge(title_hash)
        end
      end
    end #end title if

    if (!self.find_by_terms('//vra:dateSet/vra:date[@type="creation"]/vra:earliestDate').nil? and !self.find_by_terms('//vra:dateSet/vra:date[@type="creation"]/vra:earliestDate').empty?)
      date_node = self.find_by_terms('//vra:dateSet/vra:date[@type="creation"]/vra:earliestDate')
      if (!date_node.nil?)
        date_hash = Hash["date_dil" => date_node.text]
        solr_doc = solr_doc.merge(date_hash)
      end
    end

    if (!self.find_by_terms('//vra:agentSet/vra:agent').nil? and !self.find_by_terms('//vra:agentSet/vra:agent').empty?)
      agent_node = self.find_by_terms('//vra:agentSet/vra:agent').first.xpath('./vra:name')
      if (!agent_node.nil?)
        agent_hash = Hash["agent_dil" => agent_node.text]
        solr_doc = solr_doc.merge(agent_hash)
      end
    end

    return solr_doc
  end


  def to_solr(solr_doc=Hash.new)
    super(solr_doc)

    solr_doc = add_vra_description_to_solrdoc(solr_doc) # Add description for this object
    solr_doc = solr_doc.merge(extract_work_image_relationships) # Add relationships for this object

    # Is this an Image?
    if !self.find_by_xpath("/vra:vra/vra:image").text.blank? # Is this datastream for an Image object?
      # Set its object_type_facet
      insert_solr_field_value(solr_doc, "object_type_facet", "Multiresimage")

      # Get any associated Works and fold their descriptions into this record
      self.find_by_terms(:image,:relationSet,:imageOf, :relation_relids).each do |imageOf_pid|
        imageOf_work = Vrawork.find(imageOf_pid.text)
        imageOf_work_vra = imageOf_work.datastreams["VRA"]
        solr_doc = imageOf_work_vra.add_vra_description_to_solrdoc(solr_doc)
      end

      solr_doc['title_display'] = titleSet_display
      #solr_doc['title_alternate'] = title_altSet_display
    end

    # Is this a Work?
    if !self.find_by_xpath("/vra:vra/vra:work").text.blank? # ... or is this datastream for a Work object?
      # Set its object_type_facet
      insert_solr_field_value(solr_doc, "object_type_facet", "Vrawork")

    end

    solr_doc = add_sort_fields(solr_doc)
    solr_doc
  end

  ###################################################
  # Methods to extract VRA fields for Solr Indexing #
  ###################################################

  #########################
  # AGENT SET
  #
  # Extracts the agentSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_agentSet
    agentSet_array = {}

    # Add the display field for agentSet
    self.find_by_terms('//vra:agentSet/vra:display').each do |agent_display|
      insert_solr_field_value(agentSet_array, "agent_display_tesim", agent_display.text)
    end

    # Add a name facet for each agent
    self.find_by_terms('//vra:agentSet/vra:agent').each do |agent|
      agent.xpath('vra:name', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |agent_name|
        insert_solr_field_value(agentSet_array, "agent_name_tesim", agent_name.text)
        insert_solr_field_value(agentSet_array, "agent_name_facet", agent_name.text)
      }
    end

    return agentSet_array
  end

  #########################
  # TITLE SET
  #
  # Extracts the extract_titleSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_titleSet
    titleSet_array = {}

    # Add the display field for titleSet
    self.find_by_terms('//vra:titleSet/vra:display').each do |title_display|
      insert_solr_field_value(titleSet_array, "title_display_tesim", title_display.text)
    end

    # Add a field for each title
    self.find_by_terms('//vra:titleSet/vra:title').each do |title|
      insert_solr_field_value(titleSet_array, "title_tesim", title.text)
    end

    # Add a field for preferred title
    self.find_by_terms('//vra:titleSet/vra:title[@pref="true"]').each do |title_pref|
      insert_solr_field_value(titleSet_array, "title_pref_tesim", title_pref.text)
    end

    # Add a field for alternate title
    self.find_by_terms('//vra:titleSet/vra:title[@pref="false"]').each do |title_alt|
      insert_solr_field_value(titleSet_array, "title_alt_tesim", title_alt.text)
    end

    return titleSet_array
  end



  #########################
  # DESCRIPTION SET
  #
  # Extracts the descriptionSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_descriptionSet
    descriptionSet_array = {}

    # Add the display field for descriptionSet
    self.find_by_terms('//vra:descriptionSet/vra:display').each do |description_display|
      insert_solr_field_value(descriptionSet_array, "description_display_tesim", description_display.text)
    end

    # Add a field for each description
    self.find_by_terms('//vra:descriptionSet/vra:description').each do |description|
      insert_solr_field_value(descriptionSet_array, "description_tesim", description.text)
    end

    return descriptionSet_array
  end



  #########################
  # INSCRIPTION SET
  #
  # Extracts the inscriptionSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_inscriptionSet
    inscriptionSet_array = {}

    # Add the display field for inscriptionSet
    self.find_by_terms('//vra:inscriptionSet/vra:display').each do |inscription_display|
      insert_solr_field_value(inscriptionSet_array, "inscription_display_tesim", inscription_display.text)
    end

    # Add a field for each inscription
    self.find_by_terms('//vra:inscriptionSet/vra:inscription').each do |inscription|
      inscription.xpath('vra:text', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |inscription_text|
        insert_solr_field_value(inscriptionSet_array, "inscription_tesim", inscription_text.text)
      }
    end

    return inscriptionSet_array
  end



  #########################
  # DATE SET
  #
  # Extracts the dateSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_dateSet
    dateSet_array = {}

    self.find_by_terms('//vra:dateSet/vra:display').each do |date_display|
      insert_solr_field_value(dateSet_array, "date_display_tesim", date_display.text)
      insert_solr_field_value(dateSet_array, "date_display_facet", date_display.text)
    end

    # Add a earliest date / Not needed
    #self.find_by_terms('//vra:dateSet/vra:date').each do |date|
    # date.xpath('vra:earliestDate', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |earliestDate|
    #   insert_solr_field_value(dateSet_array, "earliestDate_t", earliestDate.text)
    # }
    # date.xpath('vra:latestDate', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |latestDate|
    #   insert_solr_field_value(dateSet_array, "latestDate_t", latestDate.text)
    # }
    #end

    return dateSet_array
  end




  #########################
  # STYLE PERIOD SET
  #
  # Extracts the stylePeriodSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_stylePeriodSet
    stylePeriodSet_array = {}
    self.find_by_terms('//vra:stylePeriodSet/vra:display').each do |stylePeriodSet_display|
      insert_solr_field_value(stylePeriodSet_array, "stylePeriodSet_display_tesim", stylePeriodSet_display.text)
      insert_solr_field_value(stylePeriodSet_array, "stylePeriod_facet", stylePeriodSet_display.text)
    end

    # Add a facet for each period
    self.find_by_terms('//vra:stylePeriodSet/vra:stylePeriod').each do |stylePeriod|
      insert_solr_field_value(stylePeriodSet_array, "stylePeriod_tesim", stylePeriod.text)
    end

    return stylePeriodSet_array
  end



  #########################
  # CULTURAL CONTEXT SET
  #
  # Extracts the culturalContextSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_culturalContextSet
    culturalContextSet_array = {}

    self.find_by_terms('//vra:culturalContextSet/vra:display').each do |culturalContextSet_display|
      insert_solr_field_value(culturalContextSet_array, "culturalContextSet_display_tesim", culturalContextSet_display.text)
    end

    # Add a field for each culturalContext
    self.find_by_terms('//vra:culturalContextSet/vra:culturalContext').each do |culturalContext|
      insert_solr_field_value(culturalContextSet_array, "culturalContext_tesim", culturalContext.text)
      insert_solr_field_value(culturalContextSet_array, "culturalContext_facet", culturalContext.text)
    end

    return culturalContextSet_array
  end



  #########################
  # MATERIAL SET
  #
  # Extracts the materialSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_materialSet
    materialSet_array = {}
    self.find_by_terms('//vra:materialSet/vra:display').each do |materialSet_display|
      insert_solr_field_value(materialSet_array, "materialSet_display_tesim", materialSet_display.text)
    end

    # Add a field for each material
    self.find_by_terms('//vra:materialSet/vra:material').each do |material|
      insert_solr_field_value(materialSet_array, "material_tesim", material.text)
    end

    return materialSet_array
  end



  #########################
  # MEASUREMENTS SET
  #
  # Extracts the measurementsSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_measurementsSet
    measurementsSet_array = {}
    self.find_by_terms('//vra:measurementsSet/vra:display').each do |measurementsSet_display|
      insert_solr_field_value(measurementsSet_array, "measurementsSet_display_tesim", measurementsSet_display.text)
    end

    # Add a field for each measurement
    self.find_by_terms('//vra:measurementsSet/vra:measurements').each do |measurements|
      insert_solr_field_value(measurementsSet_array, "measurements_tesim", measurements.text)
    end

    return measurementsSet_array
  end



  #########################
  # TECHNIQUE SET
  #
  # Extracts the techniqueSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_techniqueSet
    techniqueSet_array = {}
    self.find_by_terms('//vra:techniqueSet/vra:display').each do |techniqueSet_display|
      insert_solr_field_value(techniqueSet_array, "techniqueSet_display_tesim", techniqueSet_display.text)
    end

    # Add a field for each technique
    self.find_by_terms('//vra:techniqueSet/vra:technique').each do |technique|
      insert_solr_field_value(techniqueSet_array, "technique_tesim", technique.text)
      insert_solr_field_value(techniqueSet_array, "technique_facet", technique.text)
    end

    return techniqueSet_array
  end



  #########################
  # WORKTYPE SET
  #
  # Extracts the worktypeSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_worktypeSet
    worktypeSet_array = {}
    self.find_by_terms('//vra:worktypeSet/vra:display').each do |worktypeSet_display|
      insert_solr_field_value(worktypeSet_array, "worktypeSet_display_tesim", worktypeSet_display.text)
    end

    # Add a field for each workType
    self.find_by_terms('//vra:worktypeSet/vra:worktype').each do |worktype|
      insert_solr_field_value(worktypeSet_array, "worktype_tesim", worktype.text)
      insert_solr_field_value(worktypeSet_array, "worktype_facet", worktype.text)
    end

    return worktypeSet_array
  end



  #########################
  # LOCATION SET
  #
  # Extracts the locationSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_locationSet
    locationSet_array = {}
    self.find_by_terms('//vra:locationSet/vra:display').each do |location_display|
      insert_solr_field_value(locationSet_array, "location_display_tesim", location_display.text)
    end

    # Add a field for each location
    self.find_by_terms('//vra:locationSet/vra:location').each do |location|
      location.xpath('vra:name', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |name|
        insert_solr_field_value(locationSet_array, "location_name_tesim", name.text)
      }
    end

    return locationSet_array
  end



  #########################
  # SOURCE SET
  #
  # Extracts the sourceSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_sourceSet
    sourceSet_array = {}
    self.find_by_terms('//vra:sourceSet/vra:display').each do |source_display|
      insert_solr_field_value(sourceSet_array, "source_display_tesim", source_display.text)
    end

    # Add a field for each source
    self.find_by_terms('//vra:sourceSet/vra:source').each do |source|
      source.xpath('vra:name', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |name|
        insert_solr_field_value(sourceSet_array, "source_name_tesim", name.text)
      }
    end

    return sourceSet_array
  end

  #########################
  # SUBJECT SET
  #
  # Extracts the subjectSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_subjectSet
    subjectSet_array = {}
    self.find_by_terms('//vra:subjectSet/vra:display').each do |subject_display|
      insert_solr_field_value(subjectSet_array, "subject_display_tesim", subject_display.text)
    end

    # Add a subject term facet for each subject
    self.find_by_terms('//vra:subjectSet/vra:subject').each do |subject|
      subject.xpath('vra:term', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |term|
        insert_solr_field_value(subjectSet_array, "subject_term_tesim", term.text)
        insert_solr_field_value(subjectSet_array, "subject_term_facet", term.text)
      }
    end

    return subjectSet_array
  end


  #########################
  # TEXTREF SET
  #
  # Extracts the textrefSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_textrefSet
    textrefSet_array = {}

    self.find_by_terms('//vra:textrefSet/vra:display').each do |textref_display|
      insert_solr_field_value(textrefSet_array, "textref_display_tesim", textref_display.text)
    end
    # Add a textref facet for each textref
    self.find_by_terms('//vra:textrefSet/vra:textref').each do |textref|
      textref.xpath('vra:name', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |name|
        insert_solr_field_value(textrefSet_array, "textref_name_tesim", name.text)
      }
    end

    return textrefSet_array
  end


  #########################
  # EDITION SET
  #
  # Extracts the editionSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_editionSet
    editionSet_array = {}
    self.find_by_terms('//vra:editionSet/vra:display').each do |edition_display|
      insert_solr_field_value(editionSet_array, "edition_display_tesim", edition_display.text)
    end

    # Add a field for each edition
    self.find_by_terms('//vra:editionSet/vra:edition').each do |edition|
      edition.xpath('vra:name', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |name|
        insert_solr_field_value(editionSet_array, "edition_name_tesim", name.text)
      }
    end

    return editionSet_array
  end



  #########################
  # RIGHTS SET
  #
  # Extracts the editionSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_rightsSet
    rightsSet_array = {}
    self.find_by_terms('//vra:rightsSet/vra:display').each do |rights_display|
      insert_solr_field_value(rightsSet_array, "rights_display_tesim", rights_display.text)
    end

    # Add a field for each rights
    self.find_by_terms('//vra:rightsSet/vra:edition').each do |rights|
      rights.xpath('vra:name', 'vra' => 'http://www.vraweb.org/vracore4.htm').map { |name|
        insert_solr_field_value(rightsSet_array, "rights_name_tesim", name.text)
      }
    end

    return rightsSet_array
  end



  #########################
  # WORK/IMAGE RELATIONSHIPS
  #
  # Extracts the sourceSet fields and creates Solr::Field objects
  #
  # == Returns:
  # An array of Solr::Field objects
  def extract_work_image_relationships
    work_image_relationship_array = {}

    # Add any "imageOf" relationships
    self.find_by_terms(:image,:relationSet,:imageOf, :relation_relids).each do |relation_imageOf|
      insert_solr_field_value(work_image_relationship_array, "imageOf_tesim", relation_imageOf.text)
    end

    # And its preferred "imageOf" relationship
    self.find_by_terms(:image,:relationSet,:imageOf_preferred, :relation_relids).each do |relation_preferred|
      insert_solr_field_value(work_image_relationship_array, "preferred_imageOf_tesim", relation_preferred.text)
    end

    # Add any "imageIs" relationships
    self.find_by_terms(:work,:relationSet,:imageIs, :relation_relids).each do |relation_imageIs|
      insert_solr_field_value(work_image_relationship_array, "imageIs_tesim", relation_imageIs.text)
    end

    # And its preferred "imageIs" relationship
    self.find_by_terms(:work,:relationSet,:imageIs_preferred, :relation_relids).each do |relation_preferred|
      insert_solr_field_value(work_image_relationship_array, "preferred_imageIs_tesim", relation_preferred.text)
    end

    return work_image_relationship_array
  end



 ###########
 # Note:  This is the old version of this method from an older version of Solrizer
 # A change to return or not return an array caused a bug in the Hash merge code for the Work and Image
 # (https://github.com/projecthydra/solrizer/blob/52a36503e2c3af158cc1583d530d35d9aa2e102f/lib/solrizer/extractor.rb)
 # TODO: Move this into a patch or module
 ###########
 private

  def insert_solr_field_value(solr_doc, field_name, field_value)
    formatted_value = format_node_value(field_value)
    solr_doc[field_name] ||= []
    solr_doc[field_name] << formatted_value
    return solr_doc
  end

  def format_node_value values
    if values.nil?
      return ""
    else
      values = [values] unless values.respond_to? :map
      return values.map{|val| val.gsub(/\s+/,' ').strip}.join(" ")
    end
  end

end
