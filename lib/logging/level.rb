require 'logger'

# Methods that shouldn't be included in other classes, but are nevertheless
# useful to the Logging methods

module Logging
  module Level
    LOGGING_LEVELS = {
      'fatal' => ::Logger::FATAL,
      'error' => ::Logger::ERROR,
      'warn'  => ::Logger::WARN,
      'info'  => ::Logger::INFO,
      'debug' => ::Logger::DEBUG
    }

    def self.parse_level(level)
      return ::Logger::DEBUG if level.nil?
      try_parse_integer_level(level)
    rescue ArgumentError, TypeError
      try_parse_string_level(level)
    end

    def self.try_parse_string_level(level)
      unless String === level || Symbol === level
        raise ArgumentError, "String or Symbol expected got #{ level.class } (#{level})"
      end
      LOGGING_LEVELS.fetch(level.to_s.downcase) {
        raise UnknownLevelError, "Can't set log level to '#{ level }'"
      }
    end

    def self.try_parse_integer_level(int_level)
      level = Integer(int_level)
      if LOGGING_LEVELS.values.include?(level)
        level
      else
        raise UnknownLevelError, "Can't set log level to '#{level}' (0 to 4 expected)"
      end
    end
  end
end
