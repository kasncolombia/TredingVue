require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module CoachTradingApp
  class Application < Rails::Application
    config.load_defaults 8.0
    config.i18n.available_locales = [:en, :es]
    config.autoload_lib(ignore: %w[assets tasks])
    config.time_zone = "UTC"
  end
end
