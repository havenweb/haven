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

ec2 = Aws::EC2::Resource.new(region: REGION)


### EC2 Instance ###
ec2.instances({filters: [{name: 'tag:Name', values: ["#{NAME}Instance"]}]}).each do |i|
  puts "Terminating instance #{i.to_s}..."
    ec2.client.describe_addresses({
    filters: [
      {
        name: "instance-id",
        values: [ i.id ]
      },
    ]
  }).addresses.each do |addr|
    puts "  Dissociating associated elastic IP #{addr.public_ip}..."
    ec2.client.disassociate_address({
      association_id: addr.association_id 
    })
    puts "  Releasing associated elastic IP #{addr.public_ip}..."
    ec2.client.release_address({
      allocation_id: addr.allocation_id, 
    })
  end

  case i.state.code
  when 48  # terminated
    puts "#{i.id} is already terminated"
  else
    i.terminate
  end
  ec2.client.wait_until(:instance_terminated, {instance_ids: [i.id]})
end

### Subnet ###
puts "Finding subnets..."
ec2.subnets({
  filters: [
    {
      name: "tag:Name",
      values: ["#{NAME}Subnet"],
    },
  ],
  dry_run: false
}).each do |subnet|
  puts "Deleting subnet #{subnet.to_s}..."
  subnet.delete({
    dry_run: false,
  })
end

### Internet Gateway ###
puts "Finding Internet Gateways..."
ec2.internet_gateways({
  filters: [
    {
      name: "tag:Name",
      values: ["#{NAME}IGW"],
    },
  ],
  dry_run: false
}).each do |igw|
  puts "Deleting IGW #{igw.to_s}"
  igw.attachments.each do |vpc|
     igw.detach_from_vpc({
       dry_run: false,
       vpc_id: vpc.vpc_id
     })
  end
  igw.delete({
    dry_run: false
  })
end

### Routing Table ###
puts "Finding routing tables..."
ec2.route_tables({
  filters: [
    {
      name: "tag:Name",
      values: ["#{NAME}RouteTable"],
    },
  ],
  dry_run: false
}).each do |rt|
  puts "Deleting routing table #{rt.to_s}..."
  rt.delete({
    dry_run: false
  })
end

### VPC ###
puts "Finding VPCs..."
ec2.vpcs({
  filters: [
    {
      name: "tag:Name",
      values: ["#{NAME}VPC"],
    },
  ],
  dry_run: false
}).each do |vpc|
  puts "Deleting VPC: #{vpc.to_s}..."

puts "  Finding associated security groups..."
ec2.security_groups({
  filters: [
    {
      name: "vpc-id",
      values: [vpc.id],
    },
  ],
  dry_run: false
}).each do |sg|
  if (sg.group_name == "#{NAME}SecurityGroup")
    puts "  Deleting Security Group: #{sg.to_s}..."
    sg.delete({
      dry_run: false
    })
  end
end

  vpc.delete({
    dry_run: false
  })
end


##### IAM## ###
client = Aws::IAM::Client.new(region: REGION)
iam = Aws::IAM::Resource.new(client: client)
### Instance Profile ###
iam.instance_profiles({}).each do |profile|
  if profile.name == "#{NAME}InstanceProfileNameType"
    puts "Deleting instance profile #{profile.to_s}"
    profile.delete()
  end
end

### IAM Role ###
iam.roles({}).each do |role|
  if role.name == "#{NAME.downcase}_role"
    puts "Deleting IAM role #{role.to_s}..."
    role.attached_policies.each do |policy|
      role.detach_policy({
        policy_arn: policy.arn
      })
    end
    role.delete()
  end
end


exit


