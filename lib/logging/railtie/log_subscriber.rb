require 'set'
require 'active_support/log_subscriber'
require 'action_controller/log_subscriber'
require 'action_view/log_subscriber'
require 'request_store'

module Logging
  INTERNAL_PARAMS = ActionController::LogSubscriber::INTERNAL_PARAMS
  VIEWS_PATTERN = ActionView::LogSubscriber::VIEWS_PATTERN

  FileTransfer = Struct.new(:path, :transfer_time)
  RenderedTemplate = Struct.new(:path, :runtime, :layout)
  RequestAggregator = Struct.new(
    :method,
    :controller,
    :action,
    :format,
    :path,
    :request_id,
    :ip,
    :status,
    :view_runtime,
    :db_runtime,
    :params,
    :halting_filter,
    :sent_file,
    :redirect_location,
    :sent_data,
    :view,
    :partials
  )

  class LogSubscriber < ActiveSupport::LogSubscriber

    @action_controller_events = Set.new
    @action_view_events = Set.new

    class << self
      attr_reader :action_controller_events, :action_view_events

      # Register a new event for the the specified namespace this
      # subscriber should subscribe to.
      #
      # @param event_name [Symbol] the name of the event we'll subscribe to
      %w{controller view}.each do |namespace_part|
        namespace = "action_#{namespace_part}"
        define_method "#{namespace}_event" do |event_name|
          send("#{namespace}_events") << event_name
        end
      end
    end

    # Build an array of event patterns from the action_controller_events
    # set for use in finding subscriptions we should add and ones we should
    # remove from the default subscribers
    def self.event_patterns
      action_controller_events.map{ |event| "#{event}.action_controller" } +
        action_view_events.map { |event| "#{event}.action_view" }
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
    ACTION_PAYLOAD_KEYS = [:method, :controller, :action, :format, :path, :request_id, :ip, :status, :view_runtime, :db_runtime]
    action_controller_event def process_action(event)
      payload = event.payload
      ACTION_PAYLOAD_KEYS.each do |attr|
        aggregator[attr] = payload[attr]
      end
      aggregator.params = payload[:params].except(*INTERNAL_PARAMS)

      logger.info { aggregator_without_nils }
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

    action_view_event def render_template(event)
      aggregator.view = extract_render_data_from(event)
     end

    action_view_event def render_partial(event)
      aggregator.partials ||= []
      aggregator.partials << extract_render_data_from(event)
    end
    alias :render_collection :render_partial
    action_view_event :render_collection

    def logger
      Logging.logger
    end

    private

    def aggregator
      RequestStore[:logging_request_aggregator] ||= RequestAggregator.new
    end

    def aggregator_without_nils
      struct_without_nils(aggregator)
    end

    def clean_view_path(path)
      return nil if path.nil?
      path.sub(rails_root, '').sub(VIEWS_PATTERN, '')
    end

    def extract_render_data_from(event)
      payload = event.payload
      RenderedTemplate.new(
        clean_view_path(payload[:identifier]),
        event.duration,
        clean_view_path(payload[:layout])
      )
    end

    def rails_root
      @rails_root ||= "#{Rails.root}/"
    end

    def struct_without_nils(struct)
      struct.to_h.reject{ |_, value| value.nil? }
    end
  end
end
