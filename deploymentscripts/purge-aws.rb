#!/usr/bin/env ruby
## This script deletes ssh key and S3 bucket for the specified Haven deployment.
## That removes your ability to re-create the Haven from backups in S3.
## This is PERMANENT
## Usage: ruby purge-aws.rb <domain> [yes]
require 'aws-sdk-s3'
require 'aws-sdk-ec2'

domain = ARGV[0]
param = ARGV[1]
region = 'us-west-2'

if domain.nil?
  puts "Usage: ruby purge-aws.rb <domain>"
  exit(1)
end

confirm = false
if "yes" == param
  confirm = true
  puts "Deleting S3 bucket for #{domain} and ssh key, you have 5 seconds to crtl-c if this isn't want you want"
  sleep 5
else
  puts "Running in dry mode, pass parameter \"yes\" to actually delete everything"
end

## Delete Bucket
bucket_name = "#{domain}.storage".downcase # match with lib/ruby/aws-ec2.rb
s3_resource = Aws::S3::Resource.new(region: region)
if s3_resource.bucket(bucket_name).exists?
  puts "Deleting contents of bucket '#{bucket_name}'..."
  bucket = s3_resource.bucket(bucket_name)
  if confirm
    bucket.objects.batch_delete!({})
  end
  puts "Deleting S3 bucket '#{bucket_name}'..."
  s3_client = Aws::S3::Client.new(region: region)
  if confirm
    s3_client.delete_bucket(bucket: bucket_name)
  end
else
  puts "S3 bucket '#{bucket_name}' does not exist, skipping delete"
end

## Delete EC2 Keypair
key_pair_name = "#{domain.downcase}_key"
if File.file? "#{key_pair_name}.pem"
  puts "Deleting EC2 key pair: #{key_pair_name}"
  ec2 = Aws::EC2::Resource.new(region: region)
  if confirm
    ec2.client.delete_key_pair({
      key_name: key_pair_name
    })
    `rm -f #{key_pair_name}.pem`
  end
else ## key file does not exist
  puts "Key pair file #{key_pair_name}.pem does not exist.  Skipping delete"
end
