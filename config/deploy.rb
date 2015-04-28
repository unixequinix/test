# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'gspot.glownet.com'
set :repo_url, 'git@dev.glownet.com:acidtango/gspot.git'
set :branch, 'development'
set :deploy_to, '~/glownet_gspot'
set :bundle_without, [:darwin, :development, :test]

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/secrets.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log store tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :assets_roles, [:app]

namespace :deploy do

  desc 'Restart database'
  task :restart_db do
    on roles(:app), in: :sequence, wait: 5 do
      execute :rake, 'db:drop'
      execute :rake, 'db:create'
      execute :rake, 'db:migrate'
      execute :rake, 'db:seed'
      execute :rake, 'db:populate'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
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
