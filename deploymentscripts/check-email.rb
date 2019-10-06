require 'aws-sdk-ses'

DOMAIN = ARGV[0]
if DOMAIN.nil? or DOMAIN==""
  puts "Please specify the domain you want to check status for"
  exit(1)
end

ses = Aws::SES::Client.new
puts "Email (DKIM) status for #{DOMAIN}: " + ses.get_identity_dkim_attributes({identities: [DOMAIN]}).dkim_attributes[DOMAIN].dkim_verification_status

