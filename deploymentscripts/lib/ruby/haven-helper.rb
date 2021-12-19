require 'aws-sdk-s3'

## version is a string, represents the git hash of the repo that is installed
## bucket is the name of the bucket to write the version to.

def get_version_from_bucket(bucket:, region: "us-west-2")
  s3 = Aws::S3::Client.new(region: region)
  bucket_region = s3.get_bucket_location({
    bucket: bucket 
  }).location_constraint
  s3 = Aws::S3::Client.new(region: bucket_region) if (bucket_region != region)
  resp = s3.get_object(bucket: bucket, key: "version")
  resp.body.read
rescue Aws::S3::Errors::NoSuchKey
  return nil
end

def nginx_conf_file(appname:, domain:, ruby_version:)
<<-HEREDOC
# /etc/nginx/sites-enabled/#{ appname }.conf
server {
  listen 80;
  server_name #{ domain };
  root /var/www/#{ appname }/public;
  passenger_enabled on;
  passenger_ruby /home/ubuntu/.rbenv/versions/#{ ruby_version }/bin/ruby;
  client_max_body_size 25M;
}
HEREDOC
end

def write_nginx_conf_file(filename:, domain:, ruby_version:)
  File.open(filename,'w') {|f|
    f.puts(nginx_conf_file(appname: "haven", domain: domain, ruby_version: ruby_version))
  }
end

def scp_file(source_file:, destination_path: "~/", remote_user: "ubuntu", remote_host:, key_pair_name:)
  `scp -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" #{source_file} #{remote_user}@#{remote_host}:#{destination_path}`
end

## Assumes remote user is "ubuntu" and we're running from the home directory
def run_bash_script_remotely(source_path:, source_file:, remote_host:, key_pair_name:, parameter_string: "", as_sudo: false)
  scp_file(source_file: "#{source_path}/#{source_file}", remote_host: remote_host, key_pair_name: key_pair_name)
  sudo_prefix = ""
  sudo_prefix = "sudo " if as_sudo
  `ssh -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu@#{remote_host} '#{sudo_prefix}bash -i #{source_file} #{parameter_string}'`
end

def schedule_feed_fetches(remote_host:, key_pair_name:)
  scp_file(
    source_file: "lib/ruby/schedule_fetch.rb",
    remote_host: remote_host,
    key_pair_name: key_pair_name)

    `ssh -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu@#{remote_host} '/home/ubuntu/.rbenv/shims/ruby schedule_fetch.rb'`
end

def enable_backups(remote_host:, key_pair_name:, bucket:, region:)
  ## Script that takes the backups
  scp_file(
    source_file: "lib/ruby/take_backup.rb",
    remote_host: remote_host,
    key_pair_name: key_pair_name)

  ## Script that schedules the backups
  scp_file(
    source_file: "lib/ruby/schedule_backups.rb",
    remote_host: remote_host,
    key_pair_name: key_pair_name)

  parameter_string = "#{bucket} #{region}"
  `ssh -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu@#{remote_host} '/home/ubuntu/.rbenv/shims/ruby schedule_backups.rb #{parameter_string}'`
end


####### Haven deployment specific methods #####

def prepare_instance(key_pair_name:, remote_host:)
  source_path = "lib/bash"
  script = "ubuntu-prep.sh"

  run_bash_script_remotely(source_path: source_path, source_file: script, remote_host: remote_host, key_pair_name: key_pair_name)
end

def install_haven(key_pair_name:, remote_host:, domain:, email:, user_password:, ruby_version:, bucket_name:, region:, blog_version: "master")
  nginx_conf_filename = "haven.conf"
  create_user_filename = "lib/ruby/create_user.rb"

  ### Create and copy Nginx Config
  write_nginx_conf_file(filename: nginx_conf_filename, domain: domain, ruby_version: ruby_version)
  scp_file(source_file: nginx_conf_filename, remote_host: remote_host, key_pair_name: key_pair_name)

  ### Copy ruby script for creating the first user (used by bash install script)
  scp_file(source_file: create_user_filename, remote_host: remote_host, key_pair_name: key_pair_name)

  ### Run bash install script
  script = "ubuntu-deploy.sh"
  script_path = "lib/bash"
  parameters = "\"#{email}\" \"#{user_password}\" \"#{bucket_name}\" \"#{blog_version}\""
  run_bash_script_remotely(source_path: script_path, source_file: script, remote_host: remote_host, key_pair_name: key_pair_name, parameter_string: parameters)

  ### Schedule automated DB Backups
  enable_backups(remote_host: remote_host, key_pair_name: key_pair_name, bucket: bucket_name, region: region)

  ### Schedule automated fetch for RSS/Atom feed
  schedule_feed_fetches(remote_host: remote_host, key_pair_name: key_pair_name)

  ### Enable logrotate
  run_bash_script_remotely(source_path: "lib/bash", source_file: "logrotate.sh", remote_host: remote_host, key_pair_name: key_pair_name, as_sudo: true)


end

def run_certbot(remote_host:, domain:, key_pair_name:, email:)
  `ssh -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu@#{remote_host} 'sudo certbot --nginx -n --agree-tos --email #{email} --no-eff-email --domains #{domain} --redirect'`
end
