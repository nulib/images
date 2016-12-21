def wipeout_fedora()
  recs = ActiveFedora::Base.connection_for_pid(0).search('')
  recs.each do |rec|
    rec.delete
  end
end

def wipeout_solr(solr)
  solr.delete_by_query('*:*')
  solr.commit
end

def wipeout_db
  [Group, LockedObject, User].each(&:destroy_all)
end

namespace :images do
  namespace :wipeout do
    desc "Reset fedora to empty state"
    task fedora: :environment do
      wipeout_fedora()
    end

    desc "Reset solr to empty state"
    task solr: :environment do
      wipeout_solr(ActiveFedora.solr.conn)
    end

    desc "Reset db to empty state"
    task db: :environment do
      wipeout_db
    end
  end

  desc "Reset Fedora, Solr, and DB to empty state"
  task :wipeout => :environment do
    unless ENV['CONFIRM'] == 'yes'
      $stderr.puts <<-EOC
WARNING: This process will destroy all data

Please run `rake images:wipeout CONFIRM=yes` to confirm.
EOC
      exit 1
    end

    ['fedora','solr','db'].each do |component|
      Rake::Task["images:wipeout:#{component}"].invoke
    end
  end
end
