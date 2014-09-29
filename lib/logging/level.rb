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
      try_parse_integer_level(level)
    rescue ArgumentError
      try_parse_string_level(level)
    end

    def self.try_parse_string_level(str_level)
      raise ArgumentError, "String expected: #{str_level}" unless str_level.is_a?(String)
      LOGGING_LEVELS.fetch(str_level.downcase) {
        raise ArgumentError, "Can't set log level to '#{level}'"
      }
    end

    def self.try_parse_integer_level(int_level)
      begin
        level = Integer(int_level)
      rescue ArgumentError
        # just to be explicit about what try_parse_integer_level can raise
        raise
      end
      if LOGGING_LEVELS.values.include?(level)
        level
      else
        raise ArgumentError, "Can't set log level to '#{level}' (0 to 4 expected)"
      end
    end
  end
end