require "logging/version"
require "logging/level"
require "logging/device"
require "logger"

module Logging
  def self.set_logger(logger=nil, level=nil, rotate='daily')
    @logger = ::Logger.new(Logging::Device.from(logger), rotate)
    if level
      @logger.level = Logging::Level.parse_level(level)
    elsif logger.respond_to?(:level)
      # i.e. inherit logger level if `logger` arg is a Logger
      @logger.level = logger.level
    end
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
      Logging.logger
    end
  end
end
