def nginx_conf_file(appname:, domain:, ruby_version:)
<<-HEREDOC
# /etc/nginx/sites-enabled/#{ appname }.conf
server {
  listen 80;
  server_name #{ domain };
  root /var/www/#{ appname }/public;
  passenger_enabled on;
  passenger_ruby /home/ubuntu/.rbenv/versions/#{ ruby_version }/bin/ruby;
}
HEREDOC
end

def write_nginx_conf_file(filename:, domain:, ruby_version:)
  File.open(filename,'w') {|f|
    f.puts(nginx_conf_file(appname: "simpleblog", domain: domain, ruby_version: ruby_version))
  }
end

def scp_file(source_file:, destination_path: "~/", remote_user: "ubuntu", remote_host:, key_pair_name:)
  `scp -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" #{source_file} #{remote_user}@#{remote_host}:#{destination_path}`
end

## Assumes remote user is "ubuntu" and we're running from the home directory
def run_bash_script_remotely(source_path:, source_file:, remote_host:, key_pair_name:, parameter_string: "")
  scp_file(source_file: "#{source_path}/#{source_file}", remote_host: remote_host, key_pair_name: key_pair_name)
  `ssh -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu@#{remote_host} 'bash -i #{source_file} #{parameter_string}'`
end

####### SimpleBlog deployment specific methods #####

def prepare_instance(key_pair_name:, remote_host:)
  source_path = "lib/bash"
  script = "ubuntu-prep.sh"

  run_bash_script_remotely(source_path: source_path, source_file: script, remote_host: remote_host, key_pair_name: key_pair_name)
end

def install_simpleblog(key_pair_name:, remote_host:, domain:, email:, user_password:, ruby_version:, bucket_name:)
  nginx_conf_filename = "simpleblog.conf"
  create_user_filename = "lib/ruby/create_user.rb"

  ### Create and copy Nginx Config
  write_nginx_conf_file(filename: nginx_conf_filename, domain: domain, ruby_version: ruby_version)
  scp_file(source_file: nginx_conf_filename, remote_host: remote_host, key_pair_name: key_pair_name)

  ### Copy ruby script for creating the first user (used by bash install script)
  scp_file(source_file: create_user_filename, remote_host: remote_host, key_pair_name: key_pair_name)

  ### Run bash install script
  script = "ubuntu-deploy.sh"
  script_path = "lib/bash"
  parameters = "\"#{email}\" \"#{user_password}\" \"#{bucket_name}\""
  run_bash_script_remotely(source_path: script_path, source_file: script, remote_host: remote_host, key_pair_name: key_pair_name, parameter_string: parameters)
end

def run_certbot(remote_host:, domain:, key_pair_name:, email:)
  `ssh -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu@#{remote_host} 'sudo certbot --nginx -n --agree-tos --email #{email} --no-eff-email --domains #{domain} --redirect'`
end
