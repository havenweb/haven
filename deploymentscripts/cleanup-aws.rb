### Run this script to delete the deployed webserver
### Along with all related AWS resources
### Warning!! This is non-recoverable

#`gem install aws-sdk`

#load 'aws-helpers.rb'
require 'aws-sdk-ec2'
require 'aws-sdk-iam'
require 'aws-sdk-route53'
require 'base64'

AMI_ID = "ami-06f2f779464715dc5" # Ubuntu 18.04 LTS 64bit x86
INSTANCE_TYPE = 't2.micro'
REGION = 'us-west-2'
AZ = 'us-west-2a'
CIDR = '10.200.0.0/16'
#NAME = "SimpleBlog"

ec2 = Aws::EC2::Resource.new(region: REGION)
r53 = Aws::Route53::Resource.new.client

if (ARGV.length < 1)
  puts "Please specify your domain name as a parameter to this script"
  exit(1)
end
domain = ARGV[0] #TODO: Verify domain is owned, otherwise DNS update will fail
raise("only 1 level subdomain allowed") if (domain.split(".").count > 3)
NAME = domain

### DNS Cleanup ###
def delete_dns_record_set(r53_client:, hosted_zone:, domain:, ip_address:)
  puts "Deleting record set pointing #{domain} to #{ip_address}"
  record_set = r53_client.change_resource_record_sets({
    change_batch: {
      changes: [
        {
          action: "DELETE",
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
      comment: "#{domain} web server for #{domain}",
    },
    hosted_zone_id: hosted_zone.id,
  })
end

def find_hosted_zone(r53_client:, domain_url:)
  url_parts = domain_url.split(".")
  if (url_parts.size > 3) or (url_parts.size < 2)
    raise("invalid domain: #{domain_url}")
  end
  domain = "#{url_parts[-2]}.#{url_parts[-1]}"
  hosted_zone_list = r53_client.list_hosted_zones({
    max_items: 500
  })
  hosted_zone_list.hosted_zones.each do |hosted_zone|
    if hosted_zone.name == "#{domain}."
      puts "  Found hosted zone with ID #{hosted_zone.id} for #{domain}"
      return hosted_zone
    end
  end
  return nil
end

hosted_zone = find_hosted_zone(r53_client: r53, domain_url: domain)

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
    delete_dns_record_set(r53_client: r53, hosted_zone: hosted_zone, domain: domain, ip_address: addr.public_ip)
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
    profile.roles.each do |role|
      puts "  Removing role: #{role.name}..."
      role.attached_policies().each do |policy|
        policy.detach_role({
          role_name: role.name
        })
        policy.delete
      end
      profile.remove_role({
        role_name: role.name
      })
    end
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
      policy.delete()
    end
    role.policies.each do |policy|
      policy.delete()
    end
    role.delete()
  end
end


exit


