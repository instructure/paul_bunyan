module PaulBunyan
  module Level
    LEVEL_MAP = {
      DEBUG: Logger::DEBUG,
      INFO: Logger::INFO,
      WARN: Logger::WARN,
      ERROR: Logger::ERROR,
      FATAL: Logger::FATAL,
      UNKNOWN: Logger::UNKNOWN
    }.freeze
    LOGGING_LEVEL_KEYS = LEVEL_MAP.keys.freeze
    LOGGING_LEVELS = (Logger::DEBUG..Logger::UNKNOWN).freeze

    def self.coerce_level(level)
      coerced_level = level || Logger::DEBUG
      if level =~ /\A\s*\d+\s*\z/
        coerced_level = level.to_i
      elsif level.is_a?(String) || level.is_a?(Symbol)
        coerced_level = LEVEL_MAP[level.upcase.to_sym]
      end

      unless LOGGING_LEVELS.cover?(coerced_level)
        fail UnknownLevelError, "Unknown logging level #{level}. Please try one of: #{LOGGING_LEVEL_KEYS.join(', ')}."
      end
      coerced_level
    end
  end
end
