## Run this on the Raspberry Pi
## Before running this script, do the following:
## * Install Raspbian-Lite (Feb 2020)
##   * http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/
## * Enable SSH: `touch /Volumes/boot/ssh`
## * Enable WiFi: `cp wpa_supplicant.conf /Volumes/boot/`
## * Insert SD card in Pi, and power it up
## * SSH to pi, username: pi, password: raspberry
## * copy this script to the pi's home directory and execute it there

DOMAIN=$1
EMAIL=$2

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev git libgdbm6 libreadline-dev bcrypt

# Ruby (openssl first?)

git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
CONFIGURE_OPTS="--disable-install-doc" rbenv install 2.6.5 --verbose
rbenv global 2.6.5
gem install bundler -v 1.16.1

# NodeJS and Yarn
sudo apt-get install -y nodejs && sudo ln -sf /usr/bin/nodejs /usr/local/bin/node
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn

## For image processing in the app
sudo apt-get install -y imagemagick

# PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib libpq-dev
DB_PASS=$(openssl rand -base64 18)
sudo -u postgres createuser -s pi
sudo -u postgres psql -c "ALTER USER pi WITH PASSWORD '$DB_PASS';"

# Rails App
echo 'export RAILS_ENV=production' >> ~/.bashrc
export RAILS_ENV=production
cd /home/pi
sudo git clone https://github.com/mawise/simpleblog.git
sudo chown pi -R simpleblog
cd simpleblog
git checkout armv6l #TODO, check uname -m
bundle config build.bcrypt --use-system-libraries
bundle install --deployment --without development test

echo 'SIMPLEBLOG_DB_NAME="pi"' >> .env
echo 'SIMPLEBLOG_DB_ROLE="pi"' >> .env
echo "SIMPLEBLOG_DB_PASSWORD=\"$DB_PASS\"" >> .env

bin/rails db:create
bin/rails db:migrate
bin/rails assets:precompile

# systemd to run the app: /etc/systemd/system/simpleblog.service 
echo "[Unit]" > simpleblog.service
echo "Description=SimpleBlog Web App" >> simpleblog.service
echo "" >> simpleblog.service
echo "[Service]" >> simpleblog.service
echo "User=pi" >> simpleblog.service
echo "Group=pi" >> simpleblog.service
echo "WorkingDirectory=/home/pi/simpleblog" >> simpleblog.service
echo "Environment=PATH=/home/pi/.rbenv/shims:/home/pi/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games" >> simpleblog.service
echo "ExecStart=/home/pi/simpleblog/bin/rails s -e production -p 3000" >> simpleblog.service
echo "Restart=on-failure" >> simpleblog.service
echo "" >> simpleblog.service
echo "[Install]" >> simpleblog.service
echo "WantedBy=multi-user.target" >> simpleblog.service
sudo mv simpleblog.service /etc/systemd/system/simpleblog.service
sudo chown root /etc/systemd/system/simpleblog.service
sudo chmod 755 /etc/systemd/system/simpleblog.service

## Enable the systemd process
sudo systemctl daemon-reload
sudo systemctl enable simpleblog.service
sudo systemctl start simpleblog.service

# Apache
sudo apt install -y apache2

## Create Apache config file: /etc/apache2/sites-available/001-simpleblog.conf
echo "<VirtualHost *:80>" > 001-simpleblog.conf
echo "  ServerName $DOMAIN" >> 001-simpleblog.conf
echo "  DocumentRoot /home/pi/simpleblog/public" >> 001-simpleblog.conf
echo "  <Location />" >> 001-simpleblog.conf
echo "    Require all granted" >> 001-simpleblog.conf
echo "  </Location>" >> 001-simpleblog.conf
echo "  RewriteEngine on" >> 001-simpleblog.conf
echo "  RequestHeader set X-Forwarded-Proto expr=%{REQUEST_SCHEME}" >> 001-simpleblog.conf
echo "  RewriteRule ^/?$ /index.html" >> 001-simpleblog.conf
echo "  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f" >> 001-simpleblog.conf
echo "  RewriteRule ^/(.*)$ http://127.0.0.1:3000%{REQUEST_URI} [P,QSA,L]" >> 001-simpleblog.conf
echo "</VirtualHost>" >> 001-simpleblog.conf
sudo mv 001-simpleblog.conf /etc/apache2/sites-available/001-simpleblog.conf
sudo chown root /etc/apache2/sites-available/001-simpleblog.conf
sudo chmod 644 /etc/apache2/sites-available/001-simpleblog.conf

## Enable new apache config
sudo a2enmod rewrite proxy proxy_http headers
sudo a2ensite 001-simpleblog
sudo a2dissite 000-default
sudo systemctl restart apache2

## HTTPS with Letsencrypt
wget https://dl.eff.org/certbot-auto
sudo mv certbot-auto /usr/local/bin/certbot-auto
sudo chown root /usr/local/bin/certbot-auto
sudo chmod 0755 /usr/local/bin/certbot-auto
sudo /usr/local/bin/certbot-auto --apache -n --agree-tos --email "$EMAIL" --no-eff-email --domains $DOMAIN --redirect

## Rewrite Apache config to fix http -> https redirect
cd /home/pi
echo "<VirtualHost *:80>" > 001-simpleblog.conf
echo "  ServerName $DOMAIN" >> 001-simpleblog.conf
echo "  DocumentRoot /home/pi/simpleblog/public" >> 001-simpleblog.conf
echo "  <Location />" >> 001-simpleblog.conf
echo "    Require all granted" >> 001-simpleblog.conf
echo "  </Location>" >> 001-simpleblog.conf
echo "  RewriteEngine on" >> 001-simpleblog.conf
echo "  RewriteCond %{SERVER_NAME} =$DOMAIN" >> 001-simpleblog.conf
echo "  RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]" >> 001-simpleblog.conf
echo "</VirtualHost>" >> 001-simpleblog.conf
sudo mv 001-simpleblog.conf /etc/apache2/sites-available/001-simpleblog.conf
sudo chown root /etc/apache2/sites-available/001-simpleblog.conf
sudo chmod 644 /etc/apache2/sites-available/001-simpleblog.conf
sudo systemctl restart apache2

# Create first user
USER_PASS==$(openssl rand -base64 18)
cd /home/pi/simpleblog
bin/rails r /home/pi/simpleblog/deploymentscripts/lib/ruby/create_user.rb $EMAIL $USER_PASS
echo "=========="
echo ""
echo "Visit: https://$DOMAIN"
echo "Login email: $EMAIL"
echo "Login password: $USER_PASS"


