require "bundler/capistrano"
require "capistrano_colors"

# application domain
set :application, "10.211.55.30"

# how many releases should be kept in history
set :keep_releases, 5

# ssh options
default_run_options[:pty] = true
set :ssh_options, {:forward_agent => true}
set :use_sudo, false

# your application repository
set :scm, :git
set :repository,  "git@codeplane.com:fnando/hackerboard.git"
set :branch, "master"

# the deployer user
set :user, "deploy"
set :runner, "www-data"
set :group, "www-data"

# the application deployment path
set :deploy_to, "/var/www/hackerboard"
set :current, "#{deploy_to}/current"

# the ssh port
set :port, 22

# set the roles
role :app, application
role :web, application
role :db,  application, :primary => true

after :deploy, "deploy:cleanup"
after :deploy, "app:setup"
after :deploy, "sphinx:config"

namespace :deploy do
  task(:restart, :roles => :app, :except => {:no_release => true}) {
    run "touch #{deploy_to}/shared/restart.txt"
  }
end

namespace :sphinx do
  desc "Regenerate Sphinx configuration"
  task :config do
    run "cd #{current} && bundle exec rake ts:config"
  end

  desc "Rebuild index"
  task :rebuild do
    run "cd #{current} && bundle exec rake ts:reindex"
  end

  desc "Index pending delta"
  task :index do
    run "cd #{current} && bundle exec rake ts:index"
  end
end

namespace :app do
  desc "Copy configuration files"
  task :setup do
    %w[
      config/database.yml
      config/sphinx.yml
    ].each do |path|
      from = "#{deploy_to}/#{path}"
      to = "#{current}/#{path}"

      run "if [ -f '#{to}' ]; then rm '#{to}'; fi; ln -s #{from} #{to}"
    end
  end
end
