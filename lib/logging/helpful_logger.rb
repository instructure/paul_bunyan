require 'forwardable'

module Logging
  class HelpfulLogger
    attr_reader :logger
    extend Forwardable

    VALID_LEVEL_NAMES = Logger.constants.select{|c| Logger.const_get(c).is_a?(Fixnum) }
    DEFAULT_OPTS = {
      shift_age: 0,
      shift_size: 1048576
    }

    def initialize(logdev = STDOUT, options = {})
      @options = options
      if logdev.is_a?(Logger)
        @logger = logdev
        self.device = Device.new(device, DEFAULT_OPTS.merge(options))
      else
        @logger = Logger.new(nil)
        self.device = Device.new(logdev, DEFAULT_OPTS.merge(options))
      end
      self.level = coerce_level(options[:level]) if options[:level]
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
      @logger.level = coerce_level(value)
    end

    private

    def coerce_level(level)
      case level
      when nil
        Logger::DEBUG
      when Numeric
        level
      when /\A\s*\d+\s*\z/ # matches space surrounded integers
        level.to_i
      when String
        coerce_string_level(level)
      else
        raise UnknownLevelError, invalid_level_exception_message(level)
      end
    end

    def coerce_string_level(level)
      level = level.upcase
      if VALID_LEVEL_NAMES.include?(level.to_sym)
        Logger.const_get(level)
      else
        raise UnknownLevelError, invalid_level_exception_message(level)
      end
    end

    def invalid_level_exception_message(level)
      "An unknown logging level (#{ level }) was supplied! Please try one of: #{ VALID_LEVEL_NAMES.join(', ') }"
    end
  end
end
