require "logging/version"
require "logger"

module Logging
  DEFAULT_OUTPUT = STDOUT

  def self.set_logger(logger = nil, level=::Logger::INFO, rotate='daily')
    logger ||= DEFAULT_OUTPUT
    @logger = (logger.is_a?(Logger) ? logger : ::Logger.new(logger, rotate))
    @logger.level = level
    @logger
  end

  def self.logger
    return @logger if @logger
    init_default_logger
  end

  def self.init_default_logger
    set_logger(DEFAULT_OUTPUT)
  end

  module Logger
    def logger
      Logging.logger
    end
  end
end
