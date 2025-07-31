# Haven

[Haven](https://havenweb.org) is a private blog application built with Ruby on Rails. Write what you want, create accounts for people you want to share with, keep up with each other using built-in RSS.

Try out a live demo at https://havenweb.org/demo.html

The following are some motivating philosophies:

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

## PikaPods

[![Run on PikaPods](https://www.pikapods.com/static/run-button.svg)](https://www.pikapods.com/pods?run=haven)

PikaPods is a great platform for hosting open source apps. They currently offer a $5 credit for new members and it costs as little as $1.64/month to host your Haven on PikaPods.  You don't even need to give them a credit card to get the $5 credit and try out Haven for a couple of months.

## KubeSail

[KubeSail](https://kubesail.com/) is a self-hosting platform that makes it easier to run a server in your home or office that runs websites & apps.  You can install Haven on Kubesail with the following Kubesail template: https://kubesail.com/template/jphj/haven

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

## Heroku

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/havenweb/haven)

The Heroku install is meant for exploration and experimentation as images uploaded to your Haven will usually disapear within 24 hours and the reader will not automatically update until you visit the reader page.  The Heroku install requires a Heroku account ~and should fall under Heroku's free-tier~. Update: Heroku is [eliminating their free tier](https://help.heroku.com/RSBRUH58/removal-of-heroku-free-product-plans-faq), Haven on Heroku will probably cost ~$16/month.

## Paid Hosting

Fully managed hosting of your personal Haven is available too, check out: https://havenweb.org/order.html

## Docker

1. Install `docker` and `docker-compose`  
   If you don't know how to install `docker` and `docker-compose`, you can find info in [introduction to docker](https://fullstackopen.com/en/part12/introduction_to_containers#installing-everything-required-for-this-part) , [overview of installing docker compose](https://docs.docker.com/compose/install/) and [get docker desktop](https://docs.docker.com/get-docker/).
   
2. Clone the repository: `git clone https://github.com/havenweb/haven.git`
3. Run `cd haven`
4. Run `docker compose up`
5. Haven will be listening on port 3000

Feel free to use the included `Dockerfile` and `docker-compose.yml`.  You will  want to modify the env vars in `docker-compose.yml` to specify a different `HAVEN_USER_EMAIL` and `HAVEN_USER_PASS`.  These will be used to create you initial user (and password) on startup.  The `docker-compose.yml` file will build the docker image from source.  If you want to use a standalone `docker-compose.yml` that pulls a pre-built image, use the file in the `deploymentscrips/` directory.

Docker images are published to the [GitHub Container Registry](https://github.com/havenweb/haven/pkgs/container/haven)

## Raspberry Pi and Other Linux Systems

I strongly suggest you use to the docker installation method above.

