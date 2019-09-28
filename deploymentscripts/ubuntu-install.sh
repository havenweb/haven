#!/bin/bash

EMAIL=$1
RAILS_USER_PASS=$2

sudo apt-get update
sudo apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev

# Ruby
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv install 2.4.1
rbenv global 2.4.1
gem install bundler -v 1.16.1 --no-rdoc --no-ri

#### Nginx And Passenger #### https://www.phusionpassenger.com/library/install/nginx/install/oss/bionic/
sudo apt-get install -y nginx

# Passenger
sudo apt-get install -y dirmngr gnupg
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger bionic main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update
sudo apt-get install -y libnginx-mod-http-passenger

# Configure Passenger
if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then sudo ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ; fi
sudo service nginx restart
#sudo /usr/bin/passenger-config validate-install
#sudo /usr/sbin/passenger-memory-stats

# NodeJS and Yarn
sudo apt-get install -y nodejs && sudo ln -sf /usr/bin/nodejs /usr/local/bin/node
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn

# PostgreSQL
### https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-18-04
sudo apt-get install -y postgresql postgresql-contrib libpq-dev
DB_PASS=$(openssl rand -base64 18)
echo 'export SIMPLEBLOG_DB_NAME="ubuntu"' >> ~/.bashrc
echo 'export SIMPLEBLOG_DB_ROLE="ubuntu"' >> ~/.bashrc
echo "export SIMPLEBLOG_DB_PASSWORD=\"$DB_PASS\"" >> ~/.bashrc
export SIMPLEBLOG_DB_NAME="ubuntu"
export SIMPLEBLOG_DB_ROLE="ubuntu"
export SIMPLEBLOG_DB_PASSWORD=\"$DB_PASS\"
sudo -u postgres createuser -s ubuntu
sudo -u postgres psql -c "ALTER USER ubuntu WITH PASSWORD '$DB_PASS';"

# Rails App
sudo apt-get install -y imagemagick
echo 'export RAILS_ENV=production' >> ~/.bashrc
export RAILS_ENV=production
cd /var/www
sudo git clone https://github.com/mawise/simpleblog.git
sudo chown ubuntu -R simpleblog
cd simpleblog
bundle install --deployment --without development test
bin/rails db:create
bin/rails db:migrate
bin/rails assets:precompile
bin/rails r ~/create_user.rb $EMAIL $RAILS_USER_PASS

# Nginx config and restart
sudo mv ~/simpleblog.conf /etc/nginx/sites-enabled/
sudo service nginx restart

sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y universe
sudo add-apt-repository -y ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y certbot python-certbot-nginx


touch ~/imdone.txt



