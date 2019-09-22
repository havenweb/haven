#`gem install aws-sdk`

load 'aws-helpers.rb'
require 'aws-sdk-ec2'
require 'aws-sdk-iam'
require 'base64'

AMI_ID = "ami-06f2f779464715dc5" # Ubuntu 18.04 LTS 64bit x86
INSTANCE_TYPE = 't2.micro'
REGION = 'us-west-2'
AZ = 'us-west-2a'
CIDR = '10.200.0.0/16'
NAME = "SimpleBlog"

##TODO: each of these section creates a resource, make the steps idempotent
# provision an EC2 instace
ec2 = Aws::EC2::Resource.new(region: REGION)

### VPC ###
puts "Creating VPC..."
vpc = ec2.create_vpc({ cidr_block: CIDR })
# Get a public DNS
vpc.modify_attribute({enable_dns_support: { value: true }})
vpc.modify_attribute({enable_dns_hostnames: { value: true }})
vpc.create_tags({ tags: [{ key: 'Name', value: "#{NAME}VPC" }]})
vpc_id = vpc.vpc_id

### Internet Gateway ###
puts "Creating Internet Gateway..."
igw = ec2.create_internet_gateway
igw.create_tags({ tags: [{ key: 'Name', value: "#{NAME}IGW" }]})
igw.attach_to_vpc(vpc_id: vpc_id)
igw_id = igw.id

### Subnet ###
puts "Creating Subnet..."
subnet = ec2.create_subnet({
  vpc_id: vpc_id,
  cidr_block: CIDR, #this subnet covers the entire VPC
  availability_zone: AZ
})
subnet.create_tags({ tags: [{ key: 'Name', value: "#{NAME}Subnet" }]})
subnet_id = subnet.id

### Security Group ###
puts "Creating Security Group..."
sg = ec2.create_security_group({
  group_name: "#{NAME}SecurityGroup",
  description: "Security group for #{NAME}",
  vpc_id: vpc_id
})
sg.authorize_egress({
  ip_permissions: [SG_SSH, SG_HTTP, SG_HTTPS, SG_TEST]
})
sg.authorize_ingress({
  ip_permissions: [SG_SSH, SG_HTTP, SG_HTTPS, SG_TEST] # TODO, remove TEST
})
sg_id = sg.id

### Routing Table ###
puts "Creating Routing Table..."
table = ec2.create_route_table({vpc_id: vpc_id})
table.create_tags({ tags: [{ key: 'Name', value: "#{NAME}RouteTable" }]})
table.create_route({
  destination_cidr_block: '0.0.0.0/0',
  gateway_id: igw_id
})
table.associate_with_subnet({subnet_id: subnet_id})
routing_table_id = table.id

### IAM Role ###
puts "Creating IAM Role..."
client = Aws::IAM::Client.new(region: REGION)
iam = Aws::IAM::Resource.new(client: client)
role = iam.create_role({
  role_name: "#{NAME.downcase}_role",
  assume_role_policy_document: POLICY_DOC
})
##TODO: limited access to S3 read/write from single bucket
role.attach_policy({policy_arn: 'arn:aws:iam::aws:policy/AmazonS3FullAccess'})
##TODO: limited SES access: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/control-user-access.html
role.attach_policy({policy_arn: 'arn:aws:iam::aws:policy/AmazonSESFullAccess'})

### IAM Instance Profile ###
puts "Creating IAM Instance Profile..."
instanceprofile = iam.create_instance_profile({instance_profile_name: "#{NAME}InstanceProfileNameType"})
puts "  Waiting 15 sec for instance profile to be ready..."
sleep 15 #profile not created immediately, give it a hot second

### Key Pair ### (only create once, don't delete on cleanup)
key_pair_name = "#{NAME.downcase}_key"
begin
  key_pair = ec2.client.create_key_pair({
    key_name: key_pair_name
  })
  File.open("#{key_pair_name}.pem","w"){|f| f.puts key_pair.key_material}
  `chmod 400 #{key_pair_name}.pem`
  puts "Key pair written to #{key_pair_name}.pem"
rescue Aws::EC2::Errors::InvalidKeyPairDuplicate
  puts "A key pair named '#{key_pair_name}' already exists."
end

### EC2 Instance ###
puts "Creating EC2 Instance..."
## User code that's executed when the instance starts
#script = `cat ubuntu-install.sh`
script = ''
encoded_script = Base64.encode64(script)
instance = ec2.create_instances({
  image_id: AMI_ID,
  min_count: 1,
  max_count: 1,
  security_group_ids: [sg_id],
  user_data: encoded_script,
  instance_type: INSTANCE_TYPE,
  placement: {
    availability_zone: AZ
  },
  subnet_id: subnet_id,
  iam_instance_profile: {
    arn: instanceprofile.arn
  },
  key_name: key_pair_name
})

puts "Waiting for EC2 instance to be ready..."
ec2.client.wait_until(:instance_status_ok, {instance_ids: [instance.first.id]})
instance.first.create_tags({ tags: [{ key: 'Name', value: "#{NAME}Instance" }, { key: 'Group', value: "#{NAME}Group" }]})
instance_id = instance.first.id

### IP Address ###
puts "Creating Elastic IP Address..."
address_allocation = ec2.client.allocate_address({
  domain: "vpc" 
})
ec2.client.associate_address({
  allocation_id: address_allocation.allocation_id, 
  instance_id: instance_id, 
})

puts "Instance ID: #{instance.first.id}"
puts "IP Address: #{address_allocation.public_ip}"
`scp -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu-install.sh ubuntu@#{address_allocation.public_ip}:~/`

puts "try: `ssh -i #{key_pair_name}.pem -o \"StrictHostKeyChecking=no\" ubuntu@#{address_allocation.public_ip}`"

# install:
#  ruby (2.4.1)
#  postgress (??)
#  nginx (??)
#  this repo

# Configure Nginx to host the app

# Configure the app to talk to postgress

# Launch the app

# Create a DNS record to point to the app

# Create a first login

