require 'aws-sdk-ec2'
require 'aws-sdk-iam'
require 'aws-sdk-route53'
require 'aws-sdk-s3'

def create_vpc(ec2_resource:, vpc_cidr:, name:)
  puts "Creating VPC..."
  vpc = ec2_resource.create_vpc({ cidr_block: vpc_cidr })
  # Get a public DNS
  vpc.modify_attribute({enable_dns_support: { value: true }})
  vpc.modify_attribute({enable_dns_hostnames: { value: true }})
  vpc.create_tags({ tags: [{ key: 'Name', value: "#{name}VPC" }]})
  vpc
end

def create_internet_gateway(ec2_resource:, vpc:, name:)
  puts "Creating Internet Gateway..."
  igw = ec2_resource.create_internet_gateway
  igw.create_tags({ tags: [{ key: 'Name', value: "#{name}IGW" }]})
  igw.attach_to_vpc(vpc_id: vpc.id)
  igw
end

def create_subnet(ec2_resource:, vpc:, vpc_cidr:, availability_zone:, name:)
  puts "Creating Subnet..."
  subnet = ec2_resource.create_subnet({
    vpc_id: vpc.id,
    cidr_block: vpc_cidr,
    availability_zone: availability_zone
  })
  subnet.create_tags({ tags: [{ key: 'Name', value: "#{name}Subnet" }]})
  subnet
end

## Used in the method below
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

def create_security_group(ec2_resource:, vpc:, name:)
  puts "Creating Security Group..."
  sg = ec2_resource.create_security_group({
    group_name: "#{name}SecurityGroup",
    description: "Security group for #{name}",
    vpc_id: vpc.id
  })
  sg_ssh = security_group_ip_rule(22)
  sg_http = security_group_ip_rule(80)
  sg_https = security_group_ip_rule(443)
  sg.authorize_egress({
    ip_permissions: [sg_ssh, sg_http, sg_https]
  })
  sg.authorize_ingress({
    ip_permissions: [sg_ssh, sg_http, sg_https]
  })
  sg
end

def create_routing_table(ec2_resource:, vpc:, internet_gateway:, subnet:, name:)
  puts "Creating Routing Table..."
  table = ec2_resource.create_route_table({vpc_id: vpc.id})
  table.create_tags({ tags: [{ key: 'Name', value: "#{name}RouteTable" }]})
  table.create_route({
    destination_cidr_block: '0.0.0.0/0',
    gateway_id: internet_gateway.id
  })
  table.associate_with_subnet({subnet_id: subnet.id})
  table
end

## bucket_name = "#{NAME}#{DOMAIN}".sub(".","").downcase
def create_s3_bucket(aws_region:, bucket_name:)
  s3_resource = Aws::S3::Resource.new(region: aws_region)
  if s3_resource.bucket(bucket_name).exists?
    puts "S3 bucket '#{bucket_name}' already exists, using it"
  else
    puts "Creating S3 bucket '#{bucket_name}'..."
    s3_client = Aws::S3::Client.new(region: REGION)
    s3_client.create_bucket(bucket: bucket_name)
  end
end


# S3 access to a bucket, used in the following method
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

## client = Aws::IAM::Client.new(region: aws_region)
## iam = Aws::IAM::Resource.new(client: client)
def create_iam_role(iam_client:, iam_resource:, aws_region:, s3_bucket_name:, name:)
  policy_doc = {
    Version:"2012-10-17",
    Statement:[{
      Effect:"Allow",
      Principal:{
        Service:"ec2.amazonaws.com"
      },
      Action:"sts:AssumeRole"
    }]
  }.to_json

  puts "Creating IAM Role..."
  role_name = "#{name.downcase}_role"
  role = iam_resource.create_role({
    role_name: role_name,
    assume_role_policy_document: policy_doc
  })
  iam_client.put_role_policy({
    role_name: role.name,
    policy_name: "#{name}-S3-#{s3_bucket_name}",
    policy_document: s3_policy(s3_bucket_name),
  })
  role
end

def create_iam_instance_profile(iam_resource:, iam_role:, name:)
  puts "Creating IAM Instance Profile..."
  instanceprofile = iam_resource.create_instance_profile({instance_profile_name: "#{name}InstanceProfileNameType"})
  puts "  Waiting 20 sec for instance profile to be ready..."
  sleep 20 #profile not created immediately, give it a hot second
  instanceprofile.add_role({
    role_name: iam_role.name
  })
  instanceprofile
end

def create_key_pair(ec2_resource:, name:)
  key_pair_name = "#{name.downcase}_key"
  begin
    key_pair = ec2_resource.client.create_key_pair({
      key_name: key_pair_name
    })
    File.open("#{key_pair_name}.pem","w"){|f| f.puts key_pair.key_material}
    `chmod 400 #{key_pair_name}.pem`
    puts "Key pair written to #{key_pair_name}.pem"
  rescue Aws::EC2::Errors::InvalidKeyPairDuplicate
    puts "A key pair named '#{key_pair_name}' already exists."
  end
  key_pair_name
end

def create_ec2_instance(ec2_resource:, ami_id:, instance_type:, security_group:, availability_zone:, subnet:, iam_instance_profile:, key_pair_name:, name:)
  puts "Creating EC2 Instance..."
  script = '' #User data script, we're not using this
  encoded_script = Base64.encode64(script)
  instance = ec2_resource.create_instances({
    image_id: ami_id,
    min_count: 1,
    max_count: 1,
    security_group_ids: [security_group.id],
    user_data: encoded_script,
    instance_type: instance_type,
    placement: {
      availability_zone: availability_zone
    },
    subnet_id: subnet.id,
    iam_instance_profile: {
      arn: iam_instance_profile.arn
    },
    key_name: key_pair_name
  })

  puts "Waiting for EC2 instance to be ready..."
  ec2_resource.client.wait_until(:instance_status_ok, {instance_ids: [instance.first.id]})
  instance.first.create_tags({ tags: [{ key: 'Name', value: "#{name}Instance" }, { key: 'Group', value: "#{name}Group" }]})
  instance.first
end

def create_ip_address(ec2_resource:, ec2_instance:)
  puts "Creating Elastic IP Address..."
  address_allocation = ec2_resource.client.allocate_address({
    domain: "vpc"
  })
  ec2_resource.client.associate_address({
    allocation_id: address_allocation.allocation_id,
    instance_id: ec2_instance.id,
  })
  address_allocation.public_ip
end

##############  DNS  ############

#r53 = Aws::Route53::Resource.new.client
def create_hosted_zone(r53_client:, domain:, name:)
  puts "Checking if a hosted zone already exists for domain #{domain}"
  hosted_zone_list = r53_client.list_hosted_zones({
    max_items: 500
  })
  hosted_zone_list.hosted_zones.each do |hosted_zone|
    if hosted_zone.name == "#{domain}."
      puts "  Using existing hosted zone with ID #{hosted_zone.id} for #{domain}"
      return hosted_zone ### early exit ###
    end
  end
  if hosted_zone_list.is_truncated ### and we didn't exit early above
    puts "Could not find a matching hosted zone, but you have over 500 zones which this script cannot handle.  Quitting..." ##TODO: handle this
    exit(1)
  end

  puts "Creating a new hosted zone for domain #{domain}"
  nonce = rand.to_s
  hosted_zone = r53_client.create_hosted_zone({
    name: domain,
    caller_reference: nonce,
    hosted_zone_config: {
      comment: name,
      private_zone: false,
    }
  })
  if (hosted_zone.change_info.status == "PENDING")
    puts "  Waiting for new hosted zone to be ready..."
    sleep 60 # This status never seems to change?
  end
  hosted_zone.hosted_zone
end

def create_dns_record_set(r53_client:, hosted_zone:, domain:, ip_address:, name:)
  puts "Creating new record set to point #{domain} to #{ip_address}"
  record_set = r53_client.change_resource_record_sets({
    change_batch: {
      changes: [
        {
          action: "UPSERT",
          resource_record_set: {
            name: domain,
            resource_records: [
              {
                value: ip_address,
              },
            ],
            ttl: 300,
            type: "A",
          },
        },
      ],
      comment: "#{name} web server for #{domain}",
    },
    hosted_zone_id: hosted_zone.id,
  })
end

##########  Short Methods  #########

def shortcut_create_instance(ami_id:, instance_type:, domain:, region:, availability_zone:, name:)
  ec2 = Aws::EC2::Resource.new(region: region)
  iam_client = Aws::IAM::Client.new(region: region)
  iam_resource = Aws::IAM::Resource.new(client: iam_client)
  r53 = Aws::Route53::Resource.new.client
  vpc_cidr = '10.200.0.0/16'
  s3_bucket_name = "#{name}#{domain}".sub(".","").downcase

  vpc = create_vpc(ec2_resource: ec2, vpc_cidr: vpc_cidr, name: name)
  igw = create_internet_gateway(ec2_resource: ec2, vpc: vpc, name: name)
  subnet = create_subnet(ec2_resource: ec2, vpc: vpc, vpc_cidr: vpc_cidr, availability_zone: availability_zone, name: name)
  security_group = create_security_group(ec2_resource: ec2, vpc: vpc, name: name)
  routing_table = create_routing_table(ec2_resource: ec2, vpc: vpc, internet_gateway: igw, subnet: subnet, name: name)
  create_s3_bucket(aws_region: region, bucket_name: s3_bucket_name)
  iam_role = create_iam_role(iam_client: iam_client, iam_resource: iam_resource, aws_region: region, s3_bucket_name: s3_bucket_name, name: name)
  iam_instance_profile = create_iam_instance_profile(iam_resource: iam_resource, iam_role: iam_role, name: name)
  key_pair_name = create_key_pair(ec2_resource: ec2, name: name)
  ec2_instance = create_ec2_instance(ec2_resource: ec2, ami_id: ami_id, instance_type: instance_type, security_group: security_group, availability_zone: availability_zone, subnet: subnet, iam_instance_profile: iam_instance_profile, key_pair_name: key_pair_name, name: name)
  ip_address = create_ip_address(ec2_resource: ec2, ec2_instance: ec2_instance)
  hosted_zone = create_hosted_zone(r53_client: r53, domain: domain, name: name)
  create_dns_record_set(r53_client: r53, hosted_zone: hosted_zone, domain: domain, name: name, ip_address: ip_address)

  output_hash = {}
  output_hash["ip_address"] = ip_address
  output_hash["key_pair_name"] = key_pair_name
  output_hash["s3_bucket_name"] = s3_bucket_name
  output_hash
end


