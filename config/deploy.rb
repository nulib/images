# config valid only for Capistrano 3.1
lock '3.8.1'

set :application, 'dil_hydra'
set :repo_url, 'git@github.com:nulib/images.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/var/www/dil_hydra'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug
# Default value for :pty is false
set :pty,  false


# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/dil-config.yml config/hydra-ldap.yml config/fedora.yml config/secrets.yml config/solr.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{jetty tmp/pids log tmp/cache} #bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

set :bundle_flags, "--deployment"
set :bundle_binstubs, -> { shared_path.join('bin') }

# rbenv setup
set :rbenv_type, :user
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"



# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do

  desc 'Enable sidekiq pro install'
  task :bundle_config_sidekiq do
    on roles(:web) do
      execute :bundle, "config gems.contribsys.com #{ENV['sidekiq_pro']}"
    end
  end

  before 'bundler:install', 'deploy:bundle_config_sidekiq'

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
