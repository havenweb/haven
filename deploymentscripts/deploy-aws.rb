load 'lib/ruby/aws-ec2.rb'
load 'lib/ruby/simpleblog-helper.rb'
require 'uri'

## Configurable Constants

ami = "ami-06f2f779464715dc5" # Ubuntu 18.04 LTS 64bit x86
instance_type = 't3a.micro'
region = 'us-west-2'
az = 'us-west-2a'
name = "SimpleBlog"
ruby_version = "2.4.1"

## Parameter Parsing

if (ARGV.length < 2)
  puts "Please specify your domain name as the first parameter to this script"
  puts "Please specify your email address (in quotes) as the second parameter to this script"
  exit(1)
end
domain = ARGV[0] #TODO: Verify domain is owned, otherwise DNS update will fail
email = ARGV[1]
if !(email =~ URI::MailTo::EMAIL_REGEXP)
  puts "#{email} is not a valid email address"
  exit(1) ## TODO, this might be wrong, provide a --force-email flag?
end
user_password = `openssl rand -base64 18`

## Provisioning and Deployment

instance_info = shortcut_create_instance(ami_id: ami, instance_type: instance_type, domain: domain, region: region, availability_zone: az, name: name)
ip_address = instance_info["ip_address"]
key_pair_name = instance_info["key_pair_name"]
s3_bucket_name = instance_info["s3_bucket_name"]

prepare_instance(key_pair_name: key_pair_name, remote_host: ip_address)

install_simpleblog(key_pair_name: key_pair_name, remote_host: ip_address, domain: domain, email: email, user_password: user_password, ruby_version: ruby_version, bucket_name: s3_bucket_name)

run_certbot(remote_host: ip_address, domain: domain, key_pair_name: key_pair_name, email: email)

puts "================"
puts "SSH: `ssh -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu@#{ip_address}`"
puts ""
puts "Visit: http://#{domain}"
puts "Login email: #{email}"
puts "Login password: #{user_password}"
