creds = Aws::InstanceProfileCredentials.new
Aws::Rails.add_action_mailer_delivery_method(:aws_sdk, credentials: creds, region: 'us-west-2')
