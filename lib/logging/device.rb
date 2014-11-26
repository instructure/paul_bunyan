require 'logger'
require 'forwardable'

module Logging
  class Device
    extend Forwardable

    def initialize(log = STDOUT, opt = {})
      @device = Logger::LogDevice.new(from(log), opt)
    end

    def_delegators :@device, :write, :close, :dev, :filename

    # Convert 'stdout' or 'stderr' special-case strings to STDOUT or STDERR
    def from(log)
      if log.is_a?(String) && log.downcase == 'stdout'
        STDOUT
      elsif log.is_a?(String) && log.downcase == 'stderr'
        STDERR
      else
        log
      end
    end

    # Return a (human-readable) string describing where the log output is
    # going, e.g. STDOUT, STDERR, /tmp/file.log, etc.
    def description
      filename || dev_description || "Unknown Log Destination (#{dev.inspect})"
    end

    def dev_description
      (m = dev.inspect.match(/IO:<([^>]+)>/)) && m[1]
    end

    def tty?
      dev.respond_to?(:tty?) && dev.tty?
    end
  end
end
