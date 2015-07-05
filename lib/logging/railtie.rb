require 'logging/rails_ext'
require 'logging/railtie/log_subscriber'

module Logging
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      STDOUT.sync = true
      Rails.logger = Logging.set_logger(STDOUT)
      Logging.logger.level = ENV['LOG_LEVEL'] || ::Rails.application.config.log_level || "INFO"
    end
  end
end
