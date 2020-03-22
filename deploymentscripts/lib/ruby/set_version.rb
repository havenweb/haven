## Call this script when installing a new blog to store
## the version (git hash) to S3.  This will allow a
## future install to use the same version and reuse the
## database backup.
`gem install aws-sdk-s3`
require 'aws-sdk-s3'

def write_version_to_bucket(version:, bucket:, region: "us-west-2")
  s3 = Aws::S3::Client.new(region: region)
  bucket_region = s3.client.get_bucket_location({
    bucket: bucket 
  }).location_constraint
  s3 = Aws::S3::Client.new(region: bucket_region) if (bucket_region != region)
  resp = s3.put_object({
    body: StringIO.new(version), 
    bucket: bucket, 
    key: "version",
  })
end

bucket = ARGV[0]

if (ARGV.length < 1)
  puts "Please specify the bucket as the first parameter"
  exit(1)
end

version = `git rev-parse HEAD`.chomp

write_version_to_bucket(version: version, bucket: bucket)
