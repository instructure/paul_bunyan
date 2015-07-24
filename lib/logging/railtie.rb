require 'logging/rails_ext'
require 'logging/railtie/log_subscriber'
require 'action_controller/log_subscriber'
require 'action_view/log_subscriber'

module Logging
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      log_level = Logging::Level.coerce_level(ENV['LOG_LEVEL'] || ::Rails.application.config.log_level || 'INFO')

      STDOUT.sync = true
      new_logger = Logging.add_logger(ActiveSupport::Logger.new(STDOUT))
      new_logger.level = log_level

      unless ::Rails.env.development? || ::Rails.env.test?
        new_logger.formatter = JSONFormatter.new
        unsubscribe_default_log_subscribers
        LogSubscriber.subscribe_to_events
      end

      Rails.logger = Logging.logger
    end

    def self.unsubscribe_default_log_subscribers
      LogSubscriber.event_patterns.each do |pattern|
        ActiveSupport::Notifications.notifier.listeners_for(pattern).each do |listener|
          conditionally_unsubscribe(listener)
        end
      end
    end

    DEFAULT_LOGGERS = [ActionController::LogSubscriber, ActionView::LogSubscriber]
    def self.conditionally_unsubscribe(listener)
      delegate = listener.instance_variable_get(:@delegate)
      ActiveSupport::Notifications.unsubscribe(listener) if DEFAULT_LOGGERS.include?(delegate.class)
    end
  end
end
