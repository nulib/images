desc "Index all fixtures"
task :index => 'index:all'

namespace :index do
  desc 'Index fixture objects in the repository.'
  task :all => :environment do
    loader = ActiveFedora::FixtureLoader.new('spec/fixtures/')
    Dir.glob("spec/fixtures/*.foxml.xml").each do |fixture_path|
      pid = File.basename(fixture_path, ".foxml.xml").sub("_",":")
      begin
        loader.reload(pid)
        puts "Updated #{pid}"
      rescue Errno::ECONNREFUSED => e
        puts "Can't connect to Fedora! Are you sure jetty is running?"
      rescue Exception => e
        puts("Received a Fedora error while loading #{pid}\n#{e}")
        logger.error("Received a Fedora error while loading #{pid}\n#{e}")
      end
    end
    
  end
end

