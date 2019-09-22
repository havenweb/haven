require 'json'

def security_group_ip_rule(port)
{
  ip_protocol: "tcp",
  from_port: port,
  to_port: port,
  ip_ranges: [
    {
      cidr_ip: "0.0.0.0/0",
    }
  ]
}
end

SG_SSH = security_group_ip_rule(22)
SG_HTTP = security_group_ip_rule(80)
SG_HTTPS = security_group_ip_rule(443)
SG_TEST = security_group_ip_rule(3000)

# Let EC2 assume a role
POLICY_DOC = {
  Version:"2012-10-17",
  Statement:[
    {
      Effect:"Allow",
      Principal:{
        Service:"ec2.amazonaws.com"
      },
      Action:"sts:AssumeRole"
  }]
}.to_json
