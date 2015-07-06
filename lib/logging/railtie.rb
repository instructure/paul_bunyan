require 'logging/rails_ext'
require 'logging/railtie/log_subscriber'
require 'action_controller/log_subscriber'
require 'action_view/log_subscriber'

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

    DEFAULT_LOGGERS = [ActionController::LogSubscriber, ActionView::LogSubscriber]
    def self.conditionally_unsubscribe(listener)
      delegate = listener.instance_variable_get(:@delegate)
      if DEFAULT_LOGGERS.include?(delegate.class)
        ActiveSupport::Notifications.unsubscribe(listener)
      end
    end
  end
end
