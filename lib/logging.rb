require "logger"

require "logging/version"
require "logging/level"
require "logging/device"
require "logging/helpful_logger"
require "logging/json_formatter"
require 'logging/railtie' if defined? ::Rails::Railtie

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
  class Error < StandardError; end
  class UnknownLevelError < Error; end

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

    def set_logger(log_like, options = {})
      @logger =
        case log_like
        when HelpfulLogger then
          log_like
        else
          HelpfulLogger.new(log_like, options).tap do |logger|
            logger.formatter = JSONFormatter.new(logger)
          end
        end
    end
  end
end
