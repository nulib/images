

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

    ENV["RAILS_ENV"] ||= "development"
    pids = ["inu:dil-4d013cb3-19ad-46f3-8106-f38ff78541bb"]

    pids.each do |pid|
      puts "About to connect to fedora!"
      puts "http://cecil.library.northwestern.edu:8983/fedora/objects/#{pid}/datastreams/VRA/content"
      puts response = RestClient.get("http://cecil.library.northwestern.edu:8983/fedora/objects/#{pid}/datastreams/VRA/content")
    end


    # figure out how to query cecil's api so it returns this image

  end
end

# come up with an array of pids? hit the production api to grab
