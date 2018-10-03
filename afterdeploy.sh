#!/bin/bash

export RAILS_ENV=bacardi
mkdir -p /home/deploy/current
cd /home/deploy/current
ln -s /home/deploy/shared/config/application.yml /home/deploy/current/config/application.yml
/home/deploy/.rvm/bin/rvm 2.5.1 do bundle install --path /home/deploy/shared/bundle --without development test --deployment --quiet
/home/deploy/.rvm/bin/rvm 2.5.1 do bundle exec rake assets:precompile
mkdir -p /home/deploy/current/assets_manifest_backup
cp /home/deploy/current/public/assets/.sprockets-manifest-32331ec6f60c14fa5941f65c7d7b2e8a.json /home/deploy/current/assets_manifest_backup
/home/deploy/.rvm/bin/rvm 2.5.1 do bundle exec rake db:migrate
/home/deploy/.rvm/bin/rvm 2.5.1 do bundle exec whenever --update-crontab arepa_staging --set 
rm -f /home/deploy/current/beforedeploy.sh
rm -f /home/deploy/current/appspec.yml
rm -f /home/deploy/current/afterdeploy.sh
passenger-config restart-app /home/deploy --ignore-app-not-running

#service nginx restart


