require 'aws-sdk-s3'

bucket = ARGV[0]
region = ARGV[1]

if (ARGV.length < 2)
  puts "Please specify the bucket as the first parameter"
  puts "Please specify the aws region as the second parameter"
  exit(1)
end

puts "Bucket: #{bucket}"
puts "Region: #{region}"

dumpfile_name = "dumpfile"

`pg_dump ubuntu > #{dumpfile_name}`

s3 = Aws::S3::Client.new(region: region)
File.open(dumpfile_name, 'rb') do |file|
  resp = s3.put_object({
    body: file,
    bucket: bucket,
    key: "db_backup"
  })
  puts resp.to_s
end
