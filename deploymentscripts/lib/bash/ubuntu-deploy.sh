#!/bin/bash

## This script requires a base image prepared with the ubuntu-prep.sh script

EMAIL=$1
RAILS_USER_PASS=$2
BUCKET_NAME=$3
BLOG_VERSION=$4

sudo apt-get update

DB_PASS=$(openssl rand -base64 18)
sudo -u postgres createuser -s ubuntu
sudo -u postgres psql -c "ALTER USER ubuntu WITH PASSWORD '$DB_PASS';"

# Rails App
echo 'export RAILS_ENV=production' >> ~/.bashrc
export RAILS_ENV=production
cd /var/www
sudo git clone https://github.com/havenweb/haven.git
sudo chown ubuntu -R haven
cd haven
git checkout $BLOG_VERSION ## master if not specified
ruby deploymentscripts/lib/ruby/set_version.rb $BUCKET_NAME

echo "AWS_BUCKET=\"$BUCKET_NAME\"" >> .env
echo 'HAVEN_DB_NAME="ubuntu"' >> .env
echo 'HAVEN_DB_ROLE="ubuntu"' >> .env
echo "HAVEN_DB_PASSWORD=\"$DB_PASS\"" >> .env

bundle install --deployment --without development test
bin/rails db:create
bin/rails db:migrate
bin/rails assets:precompile
bin/rails r ~/create_user.rb $EMAIL $RAILS_USER_PASS

# Nginx config and restart
sudo mv ~/haven.conf /etc/nginx/sites-enabled/
sudo service nginx restart

# Setup logrotate
sudo echo "/var/www/haven/log/*.log {" >> /etc/logrotate.conf
sudo echo "  daily" >> /etc/logrotate.conf
sudo echo "  missingok" >> /etc/logrotate.conf
sudo echo "  rotate 7" >> /etc/logrotate.conf
sudo echo "  notifempty" >> /etc/logrotate.conf
sudo echo "  copytruncate" >> /etc/logrotate.conf
sudo echo "}" >> /etc/logrotate.conf

touch ~/imdone.txt
