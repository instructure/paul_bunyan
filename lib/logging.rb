require "logging/version"
require "logging/level"
require "logging/device"
require "logging/json_formatter"
require "logging/logger_extensions"
require "logger"

module Logging
  def self.set_logger(logger=nil, level=nil, rotate='daily')
    if ::Logger === logger
      @logger = logger
    else
      @logger = ::Logger.new(::Logging::Device.from(logger), rotate)
      @logger.formatter = JSONFormatter.new(@logger.tty?)
    end
    @logger.level = Logging::Level.parse_level(level) if level
    @logger
  end

  def self.logger_description
    Logging::Device.describe(@logger)
  end

  def self.logger
    return @logger if @logger
    init_default_logger
  end

  def self.init_default_logger
    set_logger(Device::DEFAULT)
  end

  module Logger
    def logger
      ::Logging.logger
    end
  end
end
