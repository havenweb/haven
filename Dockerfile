FROM ruby:2.7.2

RUN apt-get update -yqq && \
    apt-get install -yqq \
	autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev git libgdbm6 libreadline-dev \
	nginx nodejs dirmngr gnupg apt-transport-https ca-certificates npm imagemagick && \
	npm install --global yarn && \
 	gem install bundler

ADD Gemfile Gemfile.lock Rakefile config.ru .ruby-version ./

ENV RAILS_ENV=production
RUN bundle update --bundler && \
    bundle config build.bcrypt --use-system-libraries && \
    bundle install --deployment --without development test

ADD . .
RUN bin/rails assets:precompile

EXPOSE 3000
CMD ["bash", "./bin/docker-start"]
