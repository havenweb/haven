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

# S3 access to a bucket
def s3_policy(bucket)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::#{bucket}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::#{bucket}/*"]
    }
  ]
}.to_json
end
