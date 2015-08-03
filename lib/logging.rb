require 'logger'

require_relative 'logging/json_formatter'
require_relative 'logging/level'
require_relative 'logging/log_relayer'
require_relative 'logging/text_formatter'
require_relative 'logging/version'

require_relative 'logging/railtie' if defined? ::Rails::Railtie

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
  class UnknownFormatterError < Error; end
  class UnknownLevelError < Error; end

  # The ONE method we care about.
  def logger
    Logging.logger
  end

  class << self
    attr_accessor :default_formatter_type
    Logging.default_formatter_type = :json

    def logger
      create_logger(STDOUT) unless @logger
      @logger
    end

    def create_logger(logdev, shift_age = 0, shift_size = 1048576, formatter_type: Logging.default_formatter_type)
      logger = Logger.new(logdev, shift_age, shift_size)
      logger.formatter = default_formatter(formatter_type) unless formatter_type.nil?
      add_logger(logger)
    end

    def add_logger(logger)
      @logger ||= LogRelayer.new
      @logger.add_logger(logger)
      logger
    end

    def remove_logger(logger)
      @logger.remove_logger(logger)
    end

    private def default_formatter(formatter_type)
      case formatter_type
      when :json
        JSONFormatter.new
      when :text
        TextFormatter.new
      else
        fail UnknownFormatterError, "Unknown formatter type #{formatter_type}"
      end
    end
  end
end
