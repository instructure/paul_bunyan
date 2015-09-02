require 'paul_bunyan/rails_ext'
require 'paul_bunyan/railtie/log_subscriber'
require 'action_controller/log_subscriber'
require 'action_view/log_subscriber'

module PaulBunyan
  class Railtie < ::Rails::Railtie
    DEFAULT_LOGGERS = [ActionController::LogSubscriber, ActionView::LogSubscriber].freeze

    def self.activesupport_formatter
      ActiveSupport::Logger::SimpleFormatter.new.tap do |formatter|
        formatter.extend ActiveSupport::TaggedLogging::Formatter
      end
    end

    def self.development_or_test?
      Rails.env.development? || Rails.env.test?
    end

    # Set up the config and some defaults
    config.logging = ActiveSupport::OrderedOptions.new
    config.logging.override_location = !Rails.env.test?
    config.logging.formatter = (development_or_test? ? activesupport_formatter : JSONFormatter.new)
    config.logging.handle_request_logging = !development_or_test?

    # hook our initializer in before the rails logging initializer
    initializer 'initalize_logger.logging', group: :all, before: :initialize_logger do |app|
      logging_config = config.logging

      new_logger = PaulBunyan.add_logger(ActiveSupport::Logger.new(log_target(app.config)))
      new_logger.level = PaulBunyan::Level.coerce_level(ENV['LOG_LEVEL'] || ::Rails.application.config.log_level || 'INFO')
      new_logger.formatter = logging_config.formatter

      if logging_config.handle_request_logging
        unsubscribe_default_log_subscribers
        LogSubscriber.subscribe_to_events
      end

      Rails.logger = PaulBunyan.logger
    end

    console do
      PaulBunyan.logger.formatter = TextFormatter.new(include_metadata: false)
    end

    def conditionally_unsubscribe(listener)
      delegate = listener.instance_variable_get(:@delegate)
      ActiveSupport::Notifications.unsubscribe(listener) if DEFAULT_LOGGERS.include?(delegate.class)
    end

    def file_target(app_config)
      path = app_config.paths['log'].first
      path_dir = File.dirname(path)
      FileUtils.mkdir_p(path_dir) unless File.exist?(path_dir)

      output = File.open(path, 'a')
      output.binmode
      output.sync = app_config.autoflush_log
      output
    end

    def log_target(app_config)
      config.logging.override_location ? stream_target : file_target(app_config)
    end

    def stream_target
      STDOUT.sync = true
      STDOUT
    end

    def unsubscribe_default_log_subscribers
      LogSubscriber.event_patterns.each do |pattern|
        ActiveSupport::Notifications.notifier.listeners_for(pattern).each do |listener|
          conditionally_unsubscribe(listener)
        end
      end
    end
  end
end
