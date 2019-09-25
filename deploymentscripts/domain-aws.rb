require 'aws-sdk-route53'

DOMAIN = ""
IP_ADDR = ""
NAME = "SimpleBlog"

r53 = Aws::Route53::Resource.new.client

hosted_zone_id = ""
puts "Checking if a hosted zone already exists for domain #{DOMAIN}"
hosted_zone_list = r53.list_hosted_zones({
  max_items: 100
})
hosted_zone_list.hosted_zones.each do |hosted_zone|
  if hosted_zone.name == "#{DOMAIN}."
    hosted_zone_id = hosted_zone.id
    puts "  Using existing hosted zone with ID #{hosted_zone_id} for #{DOMAIN}"
    break
  end
end
if hosted_zone_id == "" && hosted_zone_list.is_truncated
  puts "Could not find a matching hosted zone, but you have over 100 zones which this script cannot handle.  Quitting..."
  exit(1)
end

if hosted_zone_id == ""
  nonce = rand.to_s
  puts "Creating a new hosted zone for domain #{DOMAIN}"
  hosted_zone = r53.create_hosted_zone({
    name: DOMAIN,
    caller_reference: nonce,
    hosted_zone_config: {
      comment: NAME,
      private_zone: false,
    }
  })
  if (hosted_zone.change_info.status == "PENDING")
    puts "  Waiting for new hosted zone to be ready..."
    sleep 60 # This status never seems to change?
  end
  hosted_zone_id = hosted_zone.hosted_zone.id
end

puts "Creating new record set to point #{DOMAIN} to #{IP_ADDR}"
record_set = r53.change_resource_record_sets({
  change_batch: {
    changes: [
      {
        action: "UPSERT", 
        resource_record_set: {
          name: DOMAIN, 
          resource_records: [
            {
              value: IP_ADDR, 
            }, 
          ], 
          ttl: 60, 
          type: "A", 
        }, 
      }, 
    ], 
    comment: "#{NAME} web server for #{DOMAIN}", 
  }, 
  hosted_zone_id: hosted_zone_id, 
})
