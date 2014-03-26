

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

    # first pid is work, second is image
    pids = ["inu:dil-b908eafe-c8c1-43bd-8b4b-b0456d495e01"]

    pids.each do |pid|
      puts "About to connect to fedora!"

      # exception handling
      begin
        response = RestClient.get("http://cecil.library.northwestern.edu:8983/fedora/objects/#{pid}/datastreams/VRA/content")

        # check the response. if it's an image, get it's associated work and try to create that first
        # then create image.
        document = Nokogiri::XML(response)

        related = document.xpath("/vra:vra/vra:image/vra:relationSet/vra:relation/@type")
        puts related.to_s
        if related.to_s == "imageOf" # this means that this is the work and can just be created
          puts "Creating the work for the image..."
          work_pid = document.xpath("/vra:vra/vra:image/vra:relationSet/vra:relation/@relids").to_s  # look up the work and create that first   # if it's an image, we need to grab it's rel pid and look that up before we can create the image
          puts "Work pid for the image: #{work_pid}"
          work_vra = RestClient.get("http://cecil.library.northwestern.edu:8983/fedora/objects/#{work_pid}/datastreams/VRA/content")
          RestClient.post("https://localhost:3000/multiresimages/create_update_fedora_object", work_vra)
        end

        puts "About to try and create this xml locally"

        RestClient.post("https://localhost:3000/multiresimages/create_update_fedora_object", response)

        # maybe try creating the datastream first?
        # pid, ds_name, ds_label
        #RestClient.post("https://localhost:3000/multiresimages/add_datastream", :pid => pid, :ds_name => "DELIV_IMG", :ds_label => "test" )

        # pid, ds_name, ds_label, ds_location, mime_type
        RestClient.post("https://localhost:3000/multiresimages/add_external_datastream", :pid => pid, :ds_name => "DELIV_IMG", :ds_label => "test", :ds_location => "https://localhost:3000/assets/c09.jpg", :mime_type => "image/jpeg" )


        # delete the record
        RestClient.post("https://localhost:3000/multiresimages/delete_fedora_object", :pid => pid )


      rescue Exception => e
        puts "Error!!!!! #{e}"
      end
      # maybe put the test images in the project repo? and then change the VRA (or the arcv_img datastream?) location to point to the local repo?
    end


    # figure out how to query cecil's api so it returns this image

  end
end

# come up with an array of pids? hit the production api to grab
