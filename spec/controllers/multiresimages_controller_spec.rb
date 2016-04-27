require 'rails_helper'

describe MultiresimagesController, :type => :request do

  ##TODO riiif -- we need test covering login check and rescue and redirect for show.

  describe "existing image with Voyager number" do
    it "raises an error if accession number matches Voyager number" do
      @xml_from_menu = File.read( "#{ Rails.root }/spec/fixtures/vra_image_sample.xml" )
      @m = Multiresimage.create( from_menu: true, vra_xml: @xml_from_menu )
      params = {
        'format' => 'xml',
        'xml' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<vra:vra\n    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n    xmlns:fn=\"http://www.w3.org/2005/xpath-functions\"\n    xmlns:vra=\"http://www.vraweb.org/vracore4.htm\"\n    xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xsi:schemaLocation=\"http://www.vraweb.org/vracore4.htm http://www.loc.gov/standards/vracore/vra-strict.xsd\">\n    <vra:image>\n        <!--Agents-->\n        <vra:agentSet>\n            <vra:agent>\n                <vra:name type=\"personal\" vocab=\"lcnaf\"/>\n                <vra:attribution/>\n                <vra:role vocab=\"RDA\"/>\n            </vra:agent>\n        </vra:agentSet>\n        <!--Cultural Context-->\n        <vra:culturalContextSet>\n            <vra:culturalContext/>\n        </vra:culturalContextSet>\n        <!--Dates-->\n        <vra:dateSet>\n            <vra:display/>\n            <vra:date type=\"creation\">\n                <vra:earliestDate>2015</vra:earliestDate>\n            </vra:date>\n        </vra:dateSet>\n        <!--Description-->\n        <vra:descriptionSet>\n            <vra:description/>\n        </vra:descriptionSet>\n        <!--Inscription-->\n        <vra:inscriptionSet>\n            <vra:inscription>\n                <vra:text/>\n            </vra:inscription>\n        </vra:inscriptionSet>\n        <!--Location-->\n        <vra:locationSet>\n            <vra:location type=\"creation\">\n                <vra:name type=\"geographic\"/>\n            </vra:location>\n            <vra:location type=\"repository\">\n                <vra:name type=\"geographic\"/>\n            </vra:location>\n            <vra:location>\n                <vra:refid source=\"DIL\"/>\n                <vra:refid source=\"Accession\">1234</vra:refid>\n            </vra:location>\n        </vra:locationSet>\n        <!--Materials-->\n        <vra:materialSet>\n            <vra:material/>\n        </vra:materialSet>\n        <!--Measurements-->\n        <vra:measurementsSet>\n            <vra:measurements/>\n        </vra:measurementsSet>\n        <!--Relation-->\n        <vra:relationSet>\n            <vra:relation pref=\"true\" type=\"imageOf\" relids=\"\"/>\n        </vra:relationSet>\n        <!--Rights-->\n        <vra:rightsSet>\n            <vra:rights>\n                <vra:rightsHolder/>\n                <vra:text/>\n            </vra:rights>\n        </vra:rightsSet>\n        <!-- Source -->\n        <vra:sourceSet>\n            <vra:source/>\n        </vra:sourceSet>\n        <!--Style Period-->\n        <vra:stylePeriodSet>\n            <vra:stylePeriod/>\n        </vra:stylePeriodSet>\n        <!--Subjects-->\n        <vra:subjectSet>\n            <vra:display/>\n            <vra:subject>\n                <vra:term type=\"geographicPlace\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"personalName\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"personalName\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"otherTopic\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"descriptiveTopic\" vocab=\"lcsh\"/>\n            </vra:subject>\n        </vra:subjectSet>\n        <!--Technique-->\n        <vra:techniqueSet>\n            <vra:technique/>\n        </vra:techniqueSet>\n        <!--Textref-->\n        <vra:textrefSet>\n            <vra:textref/>\n        </vra:textrefSet>\n        <!-- Titles -->\n        <vra:titleSet>\n            <vra:title pref=\"true\"/>\n        </vra:titleSet>\n        <!--Work Type-->\n        <vra:worktypeSet>\n            <vra:worktype/>\n        </vra:worktypeSet>\n    </vra:image>\n    <vra:work/>\n</vra:vra>",
        'path' => "lib/assets/dropbox/123/123_Rodinia.tiff",
        'accession_nbr' => "1234"
      }

      post multiresimages_path, params

      expect(response.body).to eq('<response><returnCode>Error</returnCode><description>Existing image found with this accession number</description></response>')
    end
  end

  describe "existing image with Accession number" do
    it "raises an error if accession number matches accession number" do
      @xml_from_menu2 = File.read( "#{ Rails.root }/spec/fixtures/vra_image_accession_sample.xml" )
      @m2 = Multiresimage.create( from_menu: true, vra_xml: @xml_from_menu2 )
      params = {
        'format' => 'xml',
        'xml' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<vra:vra\n    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n    xmlns:fn=\"http://www.w3.org/2005/xpath-functions\"\n    xmlns:vra=\"http://www.vraweb.org/vracore4.htm\"\n    xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xsi:schemaLocation=\"http://www.vraweb.org/vracore4.htm http://www.loc.gov/standards/vracore/vra-strict.xsd\">\n    <vra:image>\n        <!--Agents-->\n        <vra:agentSet>\n            <vra:agent>\n                <vra:name type=\"personal\" vocab=\"lcnaf\"/>\n                <vra:attribution/>\n                <vra:role vocab=\"RDA\"/>\n            </vra:agent>\n        </vra:agentSet>\n        <!--Cultural Context-->\n        <vra:culturalContextSet>\n            <vra:culturalContext/>\n        </vra:culturalContextSet>\n        <!--Dates-->\n        <vra:dateSet>\n            <vra:display/>\n            <vra:date type=\"creation\">\n                <vra:earliestDate>2015</vra:earliestDate>\n            </vra:date>\n        </vra:dateSet>\n        <!--Description-->\n        <vra:descriptionSet>\n            <vra:description/>\n        </vra:descriptionSet>\n        <!--Inscription-->\n        <vra:inscriptionSet>\n            <vra:inscription>\n                <vra:text/>\n            </vra:inscription>\n        </vra:inscriptionSet>\n        <!--Location-->\n        <vra:locationSet>\n            <vra:location type=\"creation\">\n                <vra:name type=\"geographic\"/>\n            </vra:location>\n            <vra:location type=\"repository\">\n                <vra:name type=\"geographic\"/>\n            </vra:location>\n            <vra:location>\n                <vra:refid source=\"DIL\"/>\n                <vra:refid source=\"Accession\">1234</vra:refid>\n            </vra:location>\n        </vra:locationSet>\n        <!--Materials-->\n        <vra:materialSet>\n            <vra:material/>\n        </vra:materialSet>\n        <!--Measurements-->\n        <vra:measurementsSet>\n            <vra:measurements/>\n        </vra:measurementsSet>\n        <!--Relation-->\n        <vra:relationSet>\n            <vra:relation pref=\"true\" type=\"imageOf\" relids=\"\"/>\n        </vra:relationSet>\n        <!--Rights-->\n        <vra:rightsSet>\n            <vra:rights>\n                <vra:rightsHolder/>\n                <vra:text/>\n            </vra:rights>\n        </vra:rightsSet>\n        <!-- Source -->\n        <vra:sourceSet>\n            <vra:source/>\n        </vra:sourceSet>\n        <!--Style Period-->\n        <vra:stylePeriodSet>\n            <vra:stylePeriod/>\n        </vra:stylePeriodSet>\n        <!--Subjects-->\n        <vra:subjectSet>\n            <vra:display/>\n            <vra:subject>\n                <vra:term type=\"geographicPlace\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"personalName\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"personalName\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"otherTopic\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"descriptiveTopic\" vocab=\"lcsh\"/>\n            </vra:subject>\n        </vra:subjectSet>\n        <!--Technique-->\n        <vra:techniqueSet>\n            <vra:technique/>\n        </vra:techniqueSet>\n        <!--Textref-->\n        <vra:textrefSet>\n            <vra:textref/>\n        </vra:textrefSet>\n        <!-- Titles -->\n        <vra:titleSet>\n            <vra:title pref=\"true\"/>\n        </vra:titleSet>\n        <!--Work Type-->\n        <vra:worktypeSet>\n            <vra:worktype/>\n        </vra:worktypeSet>\n    </vra:image>\n    <vra:work/>\n</vra:vra>",
        'path' => "lib/assets/dropbox/123/123_Rodinia.tiff",
        'accession_nbr' => "5678"
      }

      post multiresimages_path, params

      expect(response.body).to eq('<response><returnCode>Error</returnCode><description>Existing image found with this accession number</description></response>')
    end
  end

  describe "existing image with Accession number" do
    it "raises an error with an empty accession number" do
      params = {
        'format' => 'xml',
        'xml' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<vra:vra\n    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n    xmlns:fn=\"http://www.w3.org/2005/xpath-functions\"\n    xmlns:vra=\"http://www.vraweb.org/vracore4.htm\"\n    xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xsi:schemaLocation=\"http://www.vraweb.org/vracore4.htm http://www.loc.gov/standards/vracore/vra-strict.xsd\">\n    <vra:image>\n        <!--Agents-->\n        <vra:agentSet>\n            <vra:agent>\n                <vra:name type=\"personal\" vocab=\"lcnaf\"/>\n                <vra:attribution/>\n                <vra:role vocab=\"RDA\"/>\n            </vra:agent>\n        </vra:agentSet>\n        <!--Cultural Context-->\n        <vra:culturalContextSet>\n            <vra:culturalContext/>\n        </vra:culturalContextSet>\n        <!--Dates-->\n        <vra:dateSet>\n            <vra:display/>\n            <vra:date type=\"creation\">\n                <vra:earliestDate>2015</vra:earliestDate>\n            </vra:date>\n        </vra:dateSet>\n        <!--Description-->\n        <vra:descriptionSet>\n            <vra:description/>\n        </vra:descriptionSet>\n        <!--Inscription-->\n        <vra:inscriptionSet>\n            <vra:inscription>\n                <vra:text/>\n            </vra:inscription>\n        </vra:inscriptionSet>\n        <!--Location-->\n        <vra:locationSet>\n            <vra:location type=\"creation\">\n                <vra:name type=\"geographic\"/>\n            </vra:location>\n            <vra:location type=\"repository\">\n                <vra:name type=\"geographic\"/>\n            </vra:location>\n            <vra:location>\n                <vra:refid source=\"DIL\"/>\n                <vra:refid source=\"Accession\">1234</vra:refid>\n            </vra:location>\n        </vra:locationSet>\n        <!--Materials-->\n        <vra:materialSet>\n            <vra:material/>\n        </vra:materialSet>\n        <!--Measurements-->\n        <vra:measurementsSet>\n            <vra:measurements/>\n        </vra:measurementsSet>\n        <!--Relation-->\n        <vra:relationSet>\n            <vra:relation pref=\"true\" type=\"imageOf\" relids=\"\"/>\n        </vra:relationSet>\n        <!--Rights-->\n        <vra:rightsSet>\n            <vra:rights>\n                <vra:rightsHolder/>\n                <vra:text/>\n            </vra:rights>\n        </vra:rightsSet>\n        <!-- Source -->\n        <vra:sourceSet>\n            <vra:source/>\n        </vra:sourceSet>\n        <!--Style Period-->\n        <vra:stylePeriodSet>\n            <vra:stylePeriod/>\n        </vra:stylePeriodSet>\n        <!--Subjects-->\n        <vra:subjectSet>\n            <vra:display/>\n            <vra:subject>\n                <vra:term type=\"geographicPlace\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"personalName\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"personalName\" vocab=\"lcnaf\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"otherTopic\"/>\n            </vra:subject>\n            <vra:subject>\n                <vra:term type=\"descriptiveTopic\" vocab=\"lcsh\"/>\n            </vra:subject>\n        </vra:subjectSet>\n        <!--Technique-->\n        <vra:techniqueSet>\n            <vra:technique/>\n        </vra:techniqueSet>\n        <!--Textref-->\n        <vra:textrefSet>\n            <vra:textref/>\n        </vra:textrefSet>\n        <!-- Titles -->\n        <vra:titleSet>\n            <vra:title pref=\"true\"/>\n        </vra:titleSet>\n        <!--Work Type-->\n        <vra:worktypeSet>\n            <vra:worktype/>\n        </vra:worktypeSet>\n    </vra:image>\n    <vra:work/>\n</vra:vra>",
        'path' => "lib/assets/dropbox/123/123_Rodinia.tiff",
        'accession_nbr' => ''
      }

      post multiresimages_path, params

      expect(response.body).to eq('<response><returnCode>Error</returnCode><description>An accession number is required</description></response>')
    end
  end

  it "should publish a multiresimage and return success message with pid upon create" do
    params = {
      'format' => 'xml',
      'from_menu'=> true,
      'xml' =>   @xml_from_menu3 = File.read( "#{ Rails.root }/spec/fixtures/vra_image_from_menu_sample.xml" ),
      'path' => "#{ Rails.root }/lib/assets/dropbox/123/123_Rodinia.tiff",
      'accession_nbr' => '224321'
    }
    post multiresimages_path, params
    expect(response.body).to include("Publish successful")
    expect(response.body).to include("inu:dil")
  end


  it "should update both image and work vra" do
    @xml_from_menu3 = File.read( "#{ Rails.root }/spec/fixtures/vra_image_from_menu_sample.xml" )

    create_params = {
      'format' => 'xml',
      'from_menu'=> true,
      'xml' => "#{@xml_from_menu3}",
      'path' => "lib/assets/dropbox/123/123_Rodinia.tiff",
      'accession_nbr' => '128789',
      'id' => 'create'
    }

    post multiresimages_path, create_params

    content = response.body.to_s
    pid_str = content.split("<pid>")[1]
    pid = pid_str.split("</pid>")[0]

    image = Multiresimage.find(pid)
    image_xml = image.datastreams['VRA'].content

    image_xml.gsub!('<vra:title pref="true">Your Title</vra:title>', '<vra:title pref="true">Title Bon Bon</vra:title>')
    new_image_xml = image_xml.gsub('<vra:name type="personal" vocab="lcnaf">Your Name</vra:name>', '<vra:name type="corporate" vocab="lcnaf">Agent Bon Bon</vra:name>')

    update_params = {
      'format' => 'xml',
      'pid' => pid,
      'xml' => new_image_xml,
      'id' => 'update'
    }

    put update_vra_multiresimages_path, update_params

    @updated_image = Multiresimage.find(pid)
    @updated_image_xml = @updated_image.datastreams['VRA'].content

    expect(@updated_image_xml).to include("Title Bon Bon")
    expect(@updated_image_xml).to include("Agent Bon Bon")

    work_pid = @updated_image.preferred_related_work_pid

    @updated_work = Multiresimage.find(work_pid)
    @updated_work_xml = @updated_work.datastreams['VRA'].content

    expect(@updated_work_xml).to include("Title Bon Bon")
    expect(@updated_work_xml).to include("Agent Bon Bon")
  end

  it "should allow an admin to delete a Multiresimage record" do


  end

  it "should deny an anonymous user from deleting a Multiresimage record" do |variable|

  end

end
