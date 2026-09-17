source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "4.0.1"

gem "rails", "~> 8.0"
gem "sqlite3", ">= 2.1", group: :development
gem "pg", "~> 1.1", group: :production
gem "puma", ">= 5.0"
gem "json", "< 3"
gem "tailwindcss-rails"
gem "stimulus-rails"
gem "turbo-rails"
gem "devise"
gem "chartkick"
gem "groupdate"
gem "jbuilder"
gem "propshaft"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]
gem "csv"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
   gem "fiddle"
end

group :development do
  gem "web-console"
end
