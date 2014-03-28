

namespace :dil do

  desc "DIL Continuous Integration build"
  task :ci do
    Rake::Task['db:migrate'].invoke

    require 'jettywrapper'
    jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty')})
    Rake::Task['jetty:config'].invoke
    error = nil
    error = Jettywrapper.wrap(jetty_params) do
      puts %x[rake hydra:fixtures:refresh RAILS_ENV=test]
      Rake::Task['spec'].invoke
    end
    raise "test failures: #{error}" if error

  end


  desc "DIL Repository Cleaner"
  task :clean_repo => :environment do
    ENV["RAILS_ENV"] ||= 'test'
    ## Clean out the repository
      begin
        Multiresimage.find_each({}, :rows=>1000) do |m|
          ### Delete everything except the fixture
          m.delete unless /^inu:dil-/.match(m.pid)
        end
        DILCollection.find_each({}, :rows=>1000) { |c| c.delete }
        AdminPolicy.find_each({}, :rows=>1000) { |c| c.delete }
      rescue ActiveFedora::ObjectNotFoundError => e
        puts "Index is out of synch with repository. #{e.message}"
        puts "Aborting repository cleanup"
        #nop - index is out of synch with repository. Try solrizing
      end
  end


  desc "DIL Collections read_groups_string set to registered"
  task :read_access_on_all_collections => :environment do
    begin
      DILCollection.find(:all).each do |c|
        unless c.read_groups.include?('registered') || c.title == 'My Details' || c.title == 'My Uploads'
          c.read_groups = c.read_groups + ['registered']
          c.save!
          puts "Updating #{c.title}: #{c.read_groups_string}"
        end
      end
      puts "DONE!"
    rescue :any
      puts "An error was encountered attempting to make Collections set to registered. #{e.message}"
      puts "Aborting this task."
    end
  end


  desc "Creates test data"
  task :create_test_data => :environment do
    require 'rest_client'
    require 'nokogiri'

    ENV["RAILS_ENV"] ||= "development"

    pids = ["inu:dil-b908eafe-c8c1-43bd-8b4b-b0456d495e01",
            "inu:dil-fbdabadb-8b07-4dfd-b7b6-3459eb03d96b",
            "inu:dil-b908eafe-c8c1-43bd-8b4b-b0456d495e01",
            "inu:dil-531d05be-f1c4-4c59-8f51-e1a06c44b44b",
            "inu:dil-4320ca2c-0f3a-42ce-9079-013f377374ca"]

    pids.each do |pid|

      begin
        # Grab the VRA for this pid from staging.
        response = RestClient.get("http://cecil.library.northwestern.edu:8983/fedora/objects/#{pid}/datastreams/VRA/content")
        document = Nokogiri::XML(response)

        # This checks to see if the fedora object is a 'work' or an 'image'. If it's an image, we will query the associated work
        # and make sure the work is created locally before the image is created. Otherwise the local fedora will flip out
        related = document.xpath("/vra:vra/vra:image/vra:relationSet/vra:relation/@type")

        # If this conditional is true, it means that we need to look up the work and create that first
        if related.to_s == "imageOf"
          puts "Creating the work for the image..."
          work_pid = document.xpath("/vra:vra/vra:image/vra:relationSet/vra:relation/@relids").to_s
          puts "Work pid for the image: #{work_pid}"
          work_vra = RestClient.get("http://cecil.library.northwestern.edu:8983/fedora/objects/#{work_pid}/datastreams/VRA/content")
          RestClient.post("https://localhost:3000/multiresimages/create_update_fedora_object", work_vra)
          puts "Work has been created locally!"
        end

        # Now create the actual local record for the image VRA
        puts "Creating local fedora object using remote VRA..."
        RestClient.post("https://localhost:3000/multiresimages/create_update_fedora_object", response)
        puts "Local object created successfully!"

        # Grab the remote objectXML and parse through it for information about the deliv-img datastream and use that to create a local external datastream in fedora
        puts "Querying remote DELIV-IMG data..."
        obj_xml = RestClient.get("http://#{DIL_CONFIG["dil_fedora_username"]}:#{DIL_CONFIG["dil_fedora_password"]}@cecil.library.northwestern.edu:8983/fedora/objects/#{pid}/objectXML")
        obj_doc = Nokogiri::XML(obj_xml)

        mime_type = obj_doc.xpath("/foxml:digitalObject/foxml:datastream[@ID='DELIV-IMG']/foxml:datastreamVersion/@MIMETYPE").to_s
        puts "Mime type: #{mime_type}"
        label = obj_doc.xpath("/foxml:digitalObject/foxml:datastream[@ID='DELIV-IMG']/foxml:datastreamVersion/@LABEL").to_s
        puts "Label: #{label}"
        location = obj_doc.xpath("/foxml:digitalObject/foxml:datastream[@ID='DELIV-IMG']/foxml:datastreamVersion/foxml:contentLocation/@REF").to_s
        puts "Location: #{location}"


        RestClient.post("https://localhost:3000/multiresimages/add_external_datastream", :pid => pid, :ds_name => "DELIV-IMG", :ds_label => label, :ds_location => location, :mime_type => mime_type )


        # delete the record. this is just here in case you want to delete a local fedora record while you're testing
        #RestClient.get("https://localhost:3000/multiresimages/delete_fedora_object?pid=#{pid}" )


      rescue Exception => e
        puts "Error!!!!! #{e}"
      end
    end

  end
end
