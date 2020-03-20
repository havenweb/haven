### This file will be copied over to the webserver 
### and executed to create your admin user account

if (ARGV.length < 2)
  puts "Please specify your email as the first parameter to this script (in quotes)"
  puts "Please specify your password as the second parameter to this script (min 6 characters)"
  exit(1)
end
EMAIL = ARGV[0]
PASS = ARGV[1]
if !(EMAIL =~ URI::MailTo::EMAIL_REGEXP)
  puts "#{EMAIL} is not a valid email address"
  exit(1)
end

User.create! email: "#{EMAIL}", name: "", admin: 1, password: "#{PASS}", basic_auth_username: Devise.friendly_token.first(10), basic_auth_password: Devise.friendly_token.first(10)
