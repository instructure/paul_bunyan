require 'forwardable'

module Logging
  class HelpfulLogger
    extend Forwardable

    DEFAULT_OPTS = {
      shift_age: 0,
      shift_size: 1048576
    }

    def initialize(logdev = STDOUT, opts = {})
      if logdev.is_a?(Logger)
        @logger = logdev
        self.device = Device.new(device, DEFAULT_OPTS.merge(opts))
      else
        @logger = Logger.new(nil)
        self.device = Device.new(logdev, DEFAULT_OPTS.merge(opts))
      end
    end

    attr_reader :logger

    def_delegators :@logger,
      :debug, :debug?, :info, :info?,
      :warn, :warn?, :error, :error?,
      :fatal, :fatal?, :unknown,
      :formatter, :formatter=,
      :level, :level=, :add, :<<, :close

    def device
      @logger.instance_variable_get("@logdev")
    end

    def device=(device)
      @logger.instance_variable_set("@logdev", device)
    end

    def description
      device.description
    end
  end
end
