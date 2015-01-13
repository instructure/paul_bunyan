require 'logger'
require 'forwardable'

module Logging
  class Device
    extend Forwardable

    attr_reader :all_devices

    def initialize(log = STDOUT, opt = {})
      @device = Logger::LogDevice.new(from(log), opt)
      @all_devices = [@device]
    end

    def_delegators :@device, :close, :dev, :filename

    def write(string)
      @all_devices.each do |device|
        device.write(string)
      end
    end

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

    def with_temp_device(dev)
      @all_devices << dev
      yield
    rescue Exception => e
      self.write("An exception just happened: #{e.message}: #{e.backtrace.join('\n')}")
      raise
    ensure
      dev.close
      @all_devices.delete(dev)
    end

    def capture_start(name)
      name.to_sym.tap do |n|
        @capture_flags[n] = true
        @capture_buffers[n] = String.new
      end
    end

    def capture_end(name)
      @capture_flags[name.to_sym] = false
    end

    def captured(name)
      @capture_buffers[name.to_sym]
    end
  end
end
