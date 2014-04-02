

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
    ENV["environment"] ||= "staging"

    REMOTE_FEDORA = YAML.load_file(Rails.root.join('config', 'fedora.yml'))[ENV["environment"]]

    REMOTE_DIL_CONFIG = YAML.load_file(Rails.root.join('config', 'dil-config.yml'))[ENV["environment"]]

    pids = ["inu:dil-b908eafe-c8c1-43bd-8b4b-b0456d495e01",
            "inu:dil-fbdabadb-8b07-4dfd-b7b6-3459eb03d96b",
            "inu:dil-b908eafe-c8c1-43bd-8b4b-b0456d495e01",
            "inu:dil-531d05be-f1c4-4c59-8f51-e1a06c44b44b",
            "inu:dil-4320ca2c-0f3a-42ce-9079-013f377374ca"]

    work_pids = []

    fedora_url = REMOTE_DIL_CONFIG["dil_fedora_url"].gsub(/\/get/,"")

    pids.each do |pid|

      begin
        # Grab the VRA for this pid from staging.
        response = RestClient.get("#{fedora_url}objects/#{pid}/datastreams/VRA/content")
        document = Nokogiri::XML(response)

        # Create the work first, fedora won't throw a ActiveFedora::ObjectNotFoundError:Unable to find 'inu:dil-dabce2f5-3a95-4072-9916-be9e21fd56cc' in fedora. See logger for details.
        # which seems to be nicer
        work_pid = document.xpath("/vra:vra/vra:image/vra:relationSet/vra:relation/@relids").to_s
        work_vra = RestClient.get("#{fedora_url}objects/#{work_pid}/datastreams/VRA/content")
        RestClient.post("#{DIL_CONFIG["dil_app_url"]}multiresimages/create_update_fedora_object", work_vra)
        puts "Work has been created locally!"

        # Create the image
        puts "Creating local fedora image object using remote VRA..."
        RestClient.post("#{DIL_CONFIG["dil_app_url"]}multiresimages/create_update_fedora_object", response)
        puts "Local image object created successfully!"

        # For some reason the DIL api doesn't create a relation between the work and image, so we're doing that manually here
        img = Multiresimage.find(pid)
        work = Vrawork.find(work_pid)

        img.add_relationship(:is_image_of, "info:fedora/#{work_pid}")
        img.save

        work.add_relationship(:has_image, "info:fedora/#{pid}")
        work.save


        # Grab the remote objectXML and parse through it for information about the deliv-img datastream and use that to create a local external datastream in fedora
        puts "Querying remote DELIV-IMG data..."
        # inserting the Fedora user:password between the protocol and the server ex. http://fedoraAdmin:fedoraAdmin@server.tld/objects/pid/objectXML
        obj_xml = RestClient.get("#{fedora_url.gsub(/\/\//, "//#{REMOTE_FEDORA["user"]}:#{REMOTE_FEDORA["password"]}@")}objects/#{pid}/objectXML")
        obj_doc = Nokogiri::XML(obj_xml)

        mime_type = obj_doc.xpath("/foxml:digitalObject/foxml:datastream[@ID='DELIV-IMG']/foxml:datastreamVersion/@MIMETYPE").to_s
        puts "Mime type: #{mime_type}"
        label = obj_doc.xpath("/foxml:digitalObject/foxml:datastream[@ID='DELIV-IMG']/foxml:datastreamVersion/@LABEL").to_s
        puts "Label: #{label}"
        location = obj_doc.xpath("/foxml:digitalObject/foxml:datastream[@ID='DELIV-IMG']/foxml:datastreamVersion/foxml:contentLocation/@REF").to_s
        puts "Location: #{location}"


        RestClient.post("#{DIL_CONFIG["dil_app_url"]}multiresimages/add_external_datastream", :pid => pid, :ds_name => "DELIV-IMG", :ds_label => label, :ds_location => location, :mime_type => mime_type )

        # check to see if response.code == 200 !
        #puts "Querying remote RELS-EXT data..."
        #rels_ext = Nokogiri::XML(RestClient.get("#{fedora_url}objects/#{pid}/datastreams/RELS-EXT/content")).to_s.gsub(/\n/, "")

        #puts rels_ext
        #RestClient.post("#{DIL_CONFIG["dil_app_url"]}multiresimages/add_datastream", :pid => pid, :ds_name => "RELS-EXT", :ds_label => "Fedora Object-to-Object Relationship Metadata", :xml => rels_ext)
        #puts "RELS-EXT added successfully!"

        # delete the record. this is just here in case you want to delete a local fedora record while you're testing
        #RestClient.get("#{DIL_CONFIG["dil_app_url"]}multiresimages/delete_fedora_object?pid=#{pid}" )
        #RestClient.get("#{DIL_CONFIG["dil_app_url"]}multiresimages/delete_fedora_object?pid=#{work_pid}" )


      rescue Exception => e
        puts "Error!!!!! #{e.message}"
      end
    end

  end
end
