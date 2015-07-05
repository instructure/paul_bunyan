require 'logging/rails_ext'
require 'logging/railtie/log_subscriber'

module Logging
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      STDOUT.sync = true
      Rails.logger = Logging.set_logger(STDOUT)
      Logging.logger.level = ENV['LOG_LEVEL'] || ::Rails.application.config.log_level || "INFO"

      unsubscribe_default_log_subscribers
      LogSubscriber.subscribe_to_events
    end

    def self.unsubscribe_default_log_subscribers
      LogSubscriber.event_patterns.each do |pattern|
        ActiveSupport::Notifications.notifier.listeners_for(pattern).each do |listener|
          conditionally_unsubscribe(listener)
        end
      end
    end

    private

    def self.conditionally_unsubscribe(listener)
      delegate = listener.instance_variable_get(:@delegate)
      if delegate.class == ActionController::LogSubscriber
        ActiveSupport::Notifications.unsubscribe(listener)
      end
    end
  end
end
