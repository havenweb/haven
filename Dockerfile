FROM ruby:2.7.6-slim-buster

RUN apt-get update -yqq && \
    apt-get install -yqq \
	autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev \
        zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev git libgdbm6 libreadline-dev \
	nginx nodejs dirmngr gnupg apt-transport-https ca-certificates npm imagemagick \
        postgresql postgresql-contrib libpq-dev cron && \
	npm install --global yarn && \
 	gem install bundler -v 1.17.3 --no-document

ADD Gemfile Gemfile.lock Rakefile config.ru .ruby-version ./

# Setting MALLOC_ARENA_MAX to 2 can greatly reduce memory usage
ENV MALLOC_ARENA_MAX='2'
ENV HAVEN_DEPLOY="local"
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

RUN bundle update --bundler && \
    bundle config build.bcrypt --use-system-libraries && \
    bundle install --deployment --without development test

# Cron to automatically update feeds
COPY deploymentscripts/lib/docker/feed-fetch-cron /etc/cron.d/feed-fetch-cron
RUN chmod 0644 /etc/cron.d/feed-fetch-cron
RUN crontab /etc/cron.d/feed-fetch-cron
RUN touch /var/log/cron.log

ADD . .
RUN bin/rails assets:precompile

EXPOSE 3000

CMD ["bash", "./bin/docker-start"]
