
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
end