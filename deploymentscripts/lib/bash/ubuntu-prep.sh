#!/bin/bash

## Prepare a clean Ubuntu installation with the pre-reqs required
## to deploy a simple blog.  Assumes Ubuntu 24.04

sudo apt-get update
sudo apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6t64 libgdbm-dev gcc

# Ruby
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUBY_CONFIGURE_OPTS=--disable-install-doc rbenv install 3.3.7
rbenv global 3.3.7
gem update --system
gem update strscan --default #resolves a gem conflict
gem update base64 --default #resolves a gem conflict
gem install bundler -v 2.4.12 --no-document

#### Nginx And Passenger #### https://www.phusionpassenger.com/library/install/nginx/install/oss/bionic/
sudo apt-get install -y nginx

# Passenger
sudo apt-get install -y dirmngr gnupg apt-transport-https ca-certificates curl
curl https://oss-binaries.phusionpassenger.com/auto-software-signing-gpg-key.txt | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/phusion.gpg >/dev/null
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger noble main > /etc/apt/sources.list.d/passenger.list'
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
### https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-20-04 
sudo apt-get install -y postgresql postgresql-contrib libpq-dev

# HTTPS with Letsencrypt
sudo snap install --classic certbot

## For image processing in the app
sudo apt-get install -y imagemagick

## Create swap space for smaller instances
sudo dd if=/dev/zero of=/var/swapfile bs=1M count=512
sudo chmod 600 /var/swapfile
sudo mkswap /var/swapfile
sudo swapon /var/swapfile
echo "/var/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
