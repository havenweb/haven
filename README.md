# Haven

[Haven](https://havenweb.org) is a private blog application built with Ruby on Rails. Write what you want, create accounts for people you want to share with, keep up with each other using built-in RSS  The following are some motivating philosophies:

* Open-source. MIT License
* Privacy-first.  This is for sharing with friends and family, not commercial endevors.  If you want a blog for your company, you probably want to use WordPress or Ghost instead.
* Easy to use.  Built-in web interface for managing users, customizing the blog, and writing/editing posts with markdown and live-preview.
* Low-bandwidth friendly.  Images get downscaled to reduce page load times.  No javascript frameworks.  No ads or trackers.
* Customizable.  Add custom CSS or fonts.
* No spam. There is no self-signup for users so there is no place for unauthorized users to impact your life.
* Media support for images, videos, and audio.
* Private RSS feeds for your friends to follow you.
* Build-in RSS reader to follow your favorite blogs.

# Deployment
## AWS
* Register an account with AWS, the included scripts deploy to an AWS EC2 instance
* Buy a domain with AWS route 53, this is the domain that will point to the blog
* Setup your AWS credentials: https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html
* Clone this project onto your computer (tested with Mac OS Mojave and Ubuntu 18.04)
* Go to the `deploymentscripts` folder
* Execute `ruby deploy-aws.rb <domain> "<email>"`
  * Put your email address in quotes, this email is used for registering your HTTPS certificate
* Wait.  Deployment can take 20 minutes.
* The script will show you your login information, enjoy your blog
* Note: if anything goes wrong, you can run `ruby cleanup-aws.rb <domain>` to tear down everything the script created
* If you get this error: `cannot load such file -- aws-sdk-ec2 (LoadError)`, then type `gem install aws-sdk` and try again
## Raspberry Pi
Note, this requires a little bit more technical knowledge.  You know know how to flash an SD card and how to use the tools `ssh` and `scp`.  You should also be able to configure your own DNS and port forwarding. We're doing this fully headless, not plugging in a display or mouse/keybord to the Raspberry Pi.
* Configure your DNS to point to your home IP address.
  * If you're using AWS Route53 for your DNS, this script might be useful: https://github.com/havenweb/r53_dynamic_dns
* Flash a micro SD card with Raspberry Pi OS Lite (May 2021)
  * 32 bit: http://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/
  * or 64 bit if you know what you're doing: https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2021-05-28/
* Enable SSH and Wifi: https://raspberrytips.com/raspberry-pi-wifi-setup/
* Insert the card into the Pi, and turn it on
* Make sure you can SSH to the Pi, then copy `deploymentscripts/deploy-pi.sh` from this repository to the Pi's home directory
  * Note, the script assumes your default home directory of `/home/pi` and that you're using the default `pi` user.
* Configure your home router to forward port 80 (http) and 443 (https) to the Raspberry Pi.
  * You might also want/need to configure a static IP address for the Raspberry Pi.
* SSH to the Pi and run: `bash deploy-pi.sh DOMAIN "YOUREMAIL"`
* Wait.  On the Raspberry Pi Zero W, installation can take over three hours.
* The script will give you your initial login information, enjoy your new blog!
* Note, there are no backups setup.  You may want to backup the database (PostgreSQL) and uploaded images (`/home/pi/simpleblog/storage`).

## Other Linux Systems

Given the differences between Linux platforms I can't give fool-proof deployment instructions for every platform but take a look at the two bash scripts in `deploymentscripts/lib/bash/`.  They are the steps used for installing dependencies and the Haven application in the automated AWS deployment.  There may be differences depending on your distribution.

