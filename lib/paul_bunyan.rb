require 'logger'


require_relative 'paul_bunyan/json_formatter'
require_relative 'paul_bunyan/level'
require_relative 'paul_bunyan/log_relayer'
require_relative 'paul_bunyan/metadata_logging'
require_relative 'paul_bunyan/tagged_logging'
require_relative 'paul_bunyan/text_formatter'
require_relative 'paul_bunyan/version'

require_relative 'paul_bunyan/railtie' if defined? ::Rails::Railtie

# Example Usage:
#
#   class MyClass
#     include PaulBunyan
#
#     def initialize
#       logger.info{ "something is working!" }
#     end
#   end
#
module PaulBunyan
  class Error < StandardError; end
  class UnknownFormatterError < Error; end
  class UnknownLevelError < Error; end

  def logger
    PaulBunyan.logger
  end

  class << self
    attr_accessor :default_formatter_type
    PaulBunyan.default_formatter_type = :json

    ANSI_REGEX = /(?:\e\[|\u009b)(?:\d{1,3}(?:;\d{0,3})*)?[0-9A-MRcf-npqrsuy]/.freeze
    def strip_ansi(value)
      if value.respond_to?(:to_str)
        value.to_str.gsub(ANSI_REGEX, '')
      elsif value
        value.gsub(ANSI_REGEX, '')
      end
    end

    def logger
      create_logger(STDOUT) unless @logger
      @logger
    end

    def create_logger(logdev, shift_age = 0, shift_size = 1048576, formatter_type: PaulBunyan.default_formatter_type)
      logger = Logger.new(logdev, shift_age, shift_size)
      logger.formatter = default_formatter(formatter_type) unless formatter_type.nil?
      logger.extend(TaggedLogging) if logger.formatter.respond_to?(:tagged)
      logger.extend(MetadataLogging) if logger.formatter.respond_to?(:with_metadata)
      add_logger(logger)
    end

    def add_logger(logger)
      @logger ||= LogRelayer.new
      @logger.add_logger(logger)
      logger
    end

    def remove_logger(logger)
      @logger.remove_logger(logger) if @logger
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

# For backwards compatibility with applications that used this prior to the rename
Logging = PaulBunyan
