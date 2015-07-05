require 'set'
require 'active_support/log_subscriber'
require 'action_controller/log_subscriber'
require 'request_store'

module Logging
  INTERNAL_PARAMS = ActionController::LogSubscriber::INTERNAL_PARAMS

  RequestAggregator = Struct.new(
    :method,
    :controller,
    :action,
    :format,
    :path,
    :request_id,
    :ip,
    :status,
    :view,
    :db,
    :params
  )

  class LogSubscriber < ActiveSupport::LogSubscriber
    class << self
      attr_reader :action_controller_events
    end

    @action_controller_events = Set.new
    def self.action_controller_event(event_name)
      @action_controller_events << event_name
    end

    def self.event_patterns
      action_controller_events.map{ |event| "#{event}.action_controller" }
    end

    def self.subscribe_to_events(notifier = ActiveSupport::Notifications)
      subscriber = new
      notifier   = notifier

      subscribers << subscriber

      event_patterns.each do |pattern|
        subscriber.patterns << pattern
        notifier.subscribe(pattern, subscriber)
      end
    end

    if Rails.version.start_with?('4.0')
      attr_reader :patterns

      def initialize
        super
        @patterns ||= []
      end
    end

    action_controller_event def process_action(event)
      payload = event.payload
      [:method, :controller, :action, :format, :path, :request_id, :ip, :status].each do |attr|
        aggregator[attr] = payload[attr]
      end
      aggregator.view       = payload[:view_runtime]
      aggregator.db         = payload[:db_runtime]
      aggregator.params     = payload[:params].except(*INTERNAL_PARAMS)

      logger.info { aggregator }
    end

    def logger
      Logging.logger
    end

    private

    def aggregator
      RequestStore[:logging_request_aggregator] ||= RequestAggregator.new
    end
  end
end
