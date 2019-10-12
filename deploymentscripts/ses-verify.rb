require 'aws-sdk-route53'
require 'aws-sdk-ses'

NAME = "SimpleBlog"
DOMAIN = "simpleblogs.org"
REGION = 'us-west-2'
r53 = Aws::Route53::Resource.new.client


### Hosted Zone ###
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

### DKIM for Email ###
puts "Enabling domain for DKIM emails"
ses = Aws::SES::Client.new(region: REGION)
dkim_tokens = ses.verify_domain_dkim({
  domain: DOMAIN
}).dkim_tokens
dkim_tokens.each do |dkim_token|
  r53.change_resource_record_sets({
    change_batch: {
      changes: [
        {
          action: "UPSERT",
          resource_record_set: {
            name: "#{dkim_token}._domainkey.#{DOMAIN}",
            resource_records: [
              {
                value: "#{dkim_token}.dkim.amazonses.com",
              },
            ],
            ttl: 60,
            type: "CNAME",
          },
        },
      ],
      comment: "#{NAME} DKIM record for #{DOMAIN}",
    },
    hosted_zone_id: hosted_zone_id,
  })
end

