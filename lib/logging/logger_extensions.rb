require 'logger'

module Logging
  module LoggerExtensions
    module Logger
      def tty?
        return false unless @logdev.respond_to?(:tty?)
        @logdev.tty?
      end
    end

    module LogDevice
      def tty?
        return false unless @dev.respond_to?(:tty?)
        @dev.tty?
      end
    end
  end
end

Logger.send(:include, Logging::LoggerExtensions::Logger)
Logger::LogDevice.send(:include, Logging::LoggerExtensions::LogDevice)
