require 'forwardable'
begin
  require 'active_support/logger'
rescue LoadError
end

module Logging
  class HelpfulLogger
    attr_reader :logger
    extend Forwardable

    DEFAULT_OPTS = {
      shift_age: 0,
      shift_size: 1048576
    }
    LOGGER_CLASS = (defined?(ActiveSupport::Logger) ? ActiveSupport::Logger : ::Logger)

    def initialize(logdev = STDOUT, options = {})
      @options = options
      if logdev.is_a?(Logger)
        @logger = logdev
        self.device = Device.new(device, DEFAULT_OPTS.merge(options))
      else
        @logger = LOGGER_CLASS.new(nil)
        self.device = Device.new(logdev, DEFAULT_OPTS.merge(options))
      end
      self.level = options[:level] if options[:level]
    end

    attr_reader :logger

    def_delegators :@logger,
      :debug, :debug?,
      :info, :info?,
      :warn, :warn?,
      :error, :error?,
      :fatal, :fatal?,
      :<<, :add, :close,
      :level, :unknown

    def device
      @logger.instance_variable_get("@logdev")
    end

    def device=(device)
      @logger.instance_variable_set("@logdev", device)
    end

    def description
      device.description
    end

    def formatter
      @formatter || @logger.formatter
    end

    def formatter=(formatter)
      @logger.formatter = @formatter = formatter
    end

    def_delegators(
      :formatter,
      :push_tags,
      :pop_tags,
      :clear_tags!
    )

    def tagged(*tags)
      formatter.tagged(*tags) { yield self  }
    end

    def flush
      clear_tags!
      @logger.flush if @logger.respond_to?(:flush)
    end

    def level=(value)
      @logger.level = Logging::Level.coerce_level(value)
    end
  end
end
