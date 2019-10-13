# README

Simple blog application built with Ruby on Rails, some motivating philosophies:

* Privacy-first.  This is for sharing with friends and family, not commercial endevors.  If you want a blog for your company, you probably want to use Wordpress instead
* Easy to use.
* Low-bandwidth friendly.  Images get downscaled to reduce page load times.  No javascript.
* Customizable.  If you want to add custom CSS, you can do that
* No spam. There is no self-signup for users so there is no place for unauthorized users to impact your life

# Deployment

* Register an account with AWS, the included scripts deploy to an AWS EC2 instance
* Buy a domain with AWS route 53, this is the domain that will point to the blog
* Clone this project onto your computer (tested with Mac OS Mojave)
* Go to the `deploymentscripts` folder
* Execute `ruby deploy-aws.rb <domain> "<email>"`
  * Put your email address in quotes, this email is used for registering your HTTPS certificate
* Wait.  Deployment can take up to 20 minutes
* The script will show you your login information, enjoy your blog
* Note: if anything goes wrong, you can run `ruby cleanup-aws.rb` to tear down everything the script created
