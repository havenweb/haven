## Run this on the Raspberry Pi
## Before running this script, do the following:
## * Install Raspbian-Lite (Feb 2020)
##   * http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/
## * Enable SSH: `touch /Volumes/boot/ssh`
## * Enable WiFi: `cp wpa_supplicant.conf /Volumes/boot/`
## * Insert SD card in Pi, and power it up
## * SSH to pi, username: pi, password: raspberry
## * copy this script to the pi's home directory and execute it there

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "Specify domain as first parameter, and email (in quotes) as second parameter"


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
CONFIGURE_OPTS="--disable-install-doc" rbenv install 2.7.2 --verbose
rbenv global 2.7.2
gem install bundler -v 1.17.2 --no-document

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
sudo git clone https://github.com/havenweb/haven.git
sudo chown pi -R haven
cd haven
git checkout local
bundle config build.bcrypt --use-system-libraries
bundle install --deployment --without development test

echo 'HAVEN_DB_NAME="pi"' >> .env
echo 'HAVEN_DB_ROLE="pi"' >> .env
echo "HAVEN_DB_PASSWORD=\"$DB_PASS\"" >> .env

bin/rails db:create
bin/rails db:migrate
bin/rails assets:precompile

# systemd to run the app: /etc/systemd/system/simpleblog.service 
echo "[Unit]" > haven.service
echo "Description=Haven Web App" >> haven.service
echo "" >> haven.service
echo "[Service]" >> haven.service
echo "User=pi" >> haven.service
echo "Group=pi" >> haven.service
echo "WorkingDirectory=/home/pi/haven" >> haven.service
echo "Environment=PATH=/home/pi/.rbenv/shims:/home/pi/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games" >> haven.service
echo "ExecStart=/home/pi/haven/bin/rails s -e production -p 3000" >> haven.service
echo "Restart=on-failure" >> haven.service
echo "" >> haven.service
echo "[Install]" >> haven.service
echo "WantedBy=multi-user.target" >> haven.service
sudo mv haven.service /etc/systemd/system/haven.service
sudo chown root /etc/systemd/system/haven.service
sudo chmod 755 /etc/systemd/system/haven.service

## Enable the systemd process
sudo systemctl daemon-reload
sudo systemctl enable haven.service
sudo systemctl start haven.service

# Apache
sudo apt install -y apache2

## Create Apache config file: /etc/apache2/sites-available/001-simpleblog.conf
echo "<VirtualHost *:80>" > 001-haven.conf
echo "  ServerName $DOMAIN" >> 001-haven.conf
echo "  DocumentRoot /home/pi/haven/public" >> 001-haven.conf
echo "  <Location />" >> 001-haven.conf
echo "    Require all granted" >> 001-haven.conf
echo "  </Location>" >> 001-haven.conf
echo "  RewriteEngine on" >> 001-haven.conf
echo "  RequestHeader set X-Forwarded-Proto expr=%{REQUEST_SCHEME}" >> 001-haven.conf
echo "  RewriteRule ^/?$ /index.html" >> 001-haven.conf
echo "  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f" >> 001-haven.conf
echo "  RewriteRule ^/(.*)$ http://127.0.0.1:3000%{REQUEST_URI} [P,QSA,L]" >> 001-haven.conf
echo "</VirtualHost>" >> 001-haven.conf
sudo mv 001-haven.conf /etc/apache2/sites-available/001-haven.conf
sudo chown root /etc/apache2/sites-available/001-haven.conf
sudo chmod 644 /etc/apache2/sites-available/001-haven.conf

## Enable new apache config
sudo a2enmod rewrite proxy proxy_http headers
sudo a2ensite 001-haven
sudo a2dissite 000-default
sudo systemctl restart apache2

## HTTPS with Letsencrypt
# lock certbot version: https://community.letsencrypt.org/t/certbot-auto-no-longer-works-on-debian-based-systems/139702/7
wget https://raw.githubusercontent.com/certbot/certbot/v1.9.0/certbot-auto
sudo mv certbot-auto /usr/local/bin/certbot-auto
sudo chown root /usr/local/bin/certbot-auto
sudo chmod 0755 /usr/local/bin/certbot-auto
sudo /usr/local/bin/certbot-auto --apache -n --agree-tos --email "$EMAIL" --no-eff-email --domains $DOMAIN --redirect --no-self-upgrade

## Rewrite Apache config to fix http -> https redirect
cd /home/pi
echo "<VirtualHost *:80>" > 001-haven.conf
echo "  ServerName $DOMAIN" >> 001-haven.conf
echo "  DocumentRoot /home/pi/haven/public" >> 001-haven.conf
echo "  <Location />" >> 001-haven.conf
echo "    Require all granted" >> 001-haven.conf
echo "  </Location>" >> 001-haven.conf
echo "  RewriteEngine on" >> 001-haven.conf
echo "  RewriteCond %{SERVER_NAME} =$DOMAIN" >> 001-haven.conf
echo "  RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]" >> 001-haven.conf
echo "</VirtualHost>" >> 001-haven.conf
sudo mv 001-haven.conf /etc/apache2/sites-available/001-haven.conf
sudo chown root /etc/apache2/sites-available/001-haven.conf
sudo chmod 644 /etc/apache2/sites-available/001-haven.conf
sudo systemctl restart apache2

# Create first user
USER_PASS==$(openssl rand -base64 18)
cd /home/pi/haven
bin/rails r /home/pi/haven/deploymentscripts/lib/ruby/create_user.rb $EMAIL $USER_PASS
echo "=========="
echo ""
echo "Visit: https://$DOMAIN"
echo "Login email: $EMAIL"
echo "Login password: $USER_PASS"


