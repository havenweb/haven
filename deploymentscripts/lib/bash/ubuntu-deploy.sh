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
sudo git clone https://github.com/mawise/simpleblog.git
sudo chown ubuntu -R simpleblog
cd simpleblog
git checkout $BLOG_VERSION ## master if not specified
ruby deploymentscripts/lib/ruby/set_version.rb $BUCKET_NAME

echo "AWS_BUCKET=\"$BUCKET_NAME\"" >> .env
echo 'SIMPLEBLOG_DB_NAME="ubuntu"' >> .env
echo 'SIMPLEBLOG_DB_ROLE="ubuntu"' >> .env
echo "SIMPLEBLOG_DB_PASSWORD=\"$DB_PASS\"" >> .env

gem install nokogiri -v '1.10.9' ## bundle sometimes fails when installing this
bundle install --deployment --without development test
bin/rails db:create
bin/rails db:migrate
bin/rails assets:precompile
bin/rails r ~/create_user.rb $EMAIL $RAILS_USER_PASS

# Nginx config and restart
sudo mv ~/simpleblog.conf /etc/nginx/sites-enabled/
sudo service nginx restart

touch ~/imdone.txt
