FROM ruby:2.7.2-slim-buster

RUN echo "deb http://ftp.us.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update -yqq && \
    apt-get install --no-install-recommends -yqq \
      autoconf build-essential libpq-dev \
      nodejs apt-transport-https ca-certificates npm && \
    npm install --global yarn && \
    gem install bundler && \
    useradd --system --uid 541311 --create-home app


COPY Gemfile Gemfile.lock Rakefile config.ru .ruby-version ./

# Setting MALLOC_ARENA_MAX to 2 can greatly reduce memory usage
ENV MALLOC_ARENA_MAX='2'

RUN bundle update --bundler && \
    bundle config build.bcrypt --use-system-libraries && \
    bundle install --deployment --without development test

COPY . .
RUN bin/rails assets:precompile

EXPOSE 3000

CMD ["bin/bootstrap_webserver"]