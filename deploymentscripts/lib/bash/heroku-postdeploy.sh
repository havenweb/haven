## Used by deploy-to-heroku button to finish setup after app is deployed

bin/rails db:migrate
bin/rails r deploymentscripts/lib/ruby/create_user.rb $USER_EMAIL $USER_PASS
