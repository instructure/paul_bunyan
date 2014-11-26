require "logging/version"
require "logging/level"
require "logging/device"
require "logging/introspectable_logger"
require "logging/json_formatter"
require "logger"

# Example Usage:
#
#   class MyClass
#     include Logging
#
#     def initialize
#       logger.info{ "something is working!" }
#     end
#   end
#
module Logging
  # The ONE method we care about.
  def logger
    Logging.logger
  end

  class << self
    # The singleton @logger object for the whole app
    def logger
      @logger ||= set_logger(STDOUT)
    end

    def logger=(log_like)
      set_logger(log_like)
    end

    def set_logger(log_like, shift_age = nil, shift_size = nil)
      @logger =
        case log_like
        when IntrospectableLogger then
          log_like
        else
          opts = {}
          opts[:shift_age] = shift_age if shift_age
          opts[:shift_size] = shift_size if shift_size
          IntrospectableLogger.new(log_like, opts).tap do |logger|
            logger.formatter = JSONFormatter.new(logger)
          end
        end
    end
  end
end
