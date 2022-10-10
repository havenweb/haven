source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.6'

# For configuration files
gem 'dotenv-rails', '2.7.5'

# For parsing markdown
gem 'commonmarker', '~> 0.23'

# For validating CSS
gem 'sassc', '~> 2.4.0'

# For making user stylesheet !important
gem 'css_parser', '= 1.10.0' # pinned because we use private methods

gem 'rb-readline'

# Image processing
gem 'image_processing', '~> 1.12.2'

# For Auth
gem 'devise', '~> 4.7.1'
gem 'bcrypt', '~> 3.1.16'

# Pagination
gem 'kaminari', '~> 1.2.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.8.1'
# Use sqlite3 as the database for Active Record
#gem 'sqlite3'
gem 'pg', '~> 1.1.4'
# Use Puma as the app server
gem 'puma', '~> 4.3.12'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

#gem 'aws-sdk-rails', '~> 2.1.0'  #email with AWS SES

group :production do
  gem "aws-sdk-s3", require: false
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem "letter_opener", '~> 1.7.0' # preview mail in browser
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.37'
  gem 'selenium-webdriver', '~> 4.5'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'webdrivers', '~> 5.2'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
