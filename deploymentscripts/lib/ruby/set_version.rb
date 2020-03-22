## Call this script when installing a new blog to store
## the version (git hash) to S3.  This will allow a
## future install to use the same version and reuse the
## database backup.

load 'simpleblog-helper.rb'

bucket = ARGV[0]

if (ARGV.length < 1)
  puts "Please specify the bucket as the first parameter"
  exit(1)
end

version = `git rev-parse HEAD`.chomp

write_version_to_bucket(version: version, bucket: bucket)
