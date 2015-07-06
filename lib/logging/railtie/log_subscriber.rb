require 'set'
require 'active_support/log_subscriber'
require 'action_controller/log_subscriber'
require 'request_store'

module Logging
  INTERNAL_PARAMS = ActionController::LogSubscriber::INTERNAL_PARAMS

  FileTransfer = Struct.new(:path, :transfer_time)
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
    :params,
    :halting_filter,
    :sent_file,
    :redirect_location,
    :sent_data
  )

  class LogSubscriber < ActiveSupport::LogSubscriber
    class << self
      attr_reader :action_controller_events
    end

    @action_controller_events = Set.new

    # Register a new event for the action_controller namespace this
    # subscriber should subscribe to.
    #
    # @param event_name [Symbol] the name of the event we'll subscribe to
    def self.action_controller_event(event_name)
      @action_controller_events << event_name
    end

    # Build an array of event patterns from the action_controller_events
    # set for use in finding subscriptions we should add and ones we should
    # remove from the default subscribers
    def self.event_patterns
      action_controller_events.map{ |event| "#{event}.action_controller" }
    end

    # Subscribe to the events we've registered using action_controller_event
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

    # Handle the start_processing event in the action_controller namespace
    #
    # We're only registering for this event so the default
    # log subscribe gets booted off of it :-)
    action_controller_event def start_processing(event)
      return
    end

    # Handle the process_action event in the action_controller namespace
    #
    # We're using this to capture the vast majority of our info that goes into
    # the log line
    #
    # @param event [ActiveSupport::Notifications::Event]
    action_controller_event def process_action(event)
      payload = event.payload
      [:method, :controller, :action, :format, :path, :request_id, :ip, :status].each do |attr|
        aggregator[attr] = payload[attr]
      end
      aggregator.view       = payload[:view_runtime]
      aggregator.db         = payload[:db_runtime]
      aggregator.params     = payload[:params].except(*INTERNAL_PARAMS)

      logger.info { aggregator.to_h.reject{|_, value| value.nil? } }
    end

    action_controller_event def halted_callback(event)
      aggregator.halting_filter = event.payload[:filter].inspect
    end

    action_controller_event def send_file(event)
      payload = event.payload
      aggregator.sent_file = FileTransfer.new(payload[:path], event.duration)
    end

    action_controller_event def redirect_to(event)
      aggregator.redirect_location = event.payload[:location]
    end

    action_controller_event def send_data(event)
      payload = event.payload
      aggregator.sent_data = FileTransfer.new(payload[:filename], event.duration)
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
