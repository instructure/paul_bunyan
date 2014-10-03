require 'logger'

module Logging
  module Device
    DEFAULT = STDOUT

    # Accept the following types of log device descriptors and return an
    # object compatible with Logger.new:
    # - nil
    # - an IO or File object
    # - a file path, OR the special filenames "stdout" or "stderr"
    #   If the latter, these special filenames are interpreted to actually
    #   mean STDOUT or STDERR, respectively.
    # - a Logger object, in which case we pull out its LogDevice so that
    #   the new Logger can behave like the passed-in Logger
    def self.from(device_or_filename)
      case device_or_filename
      when NilClass
        DEFAULT
      when IO, File
        device_or_filename
      when String
        case device_or_filename.downcase
        when 'stdout' then STDOUT
        when 'stderr' then STDERR
        else
          # Return what we assume is a file path
          device_or_filename
        end
      when ::Logger
        logger = device_or_filename
        logger.instance_variable_get("@logdev")
      end
    end

    # Given a Logger object, return a string describing where the log output
    # is going, e.g. STDOUT for standard out, or /tmp/file.log for a file
    def self.describe(logger)
      case logger
      when ::Logger
        logdev = logger.instance_variable_get("@logdev")
        if logdev.filename
          return logdev.filename
        elsif logdev.dev
          if logdev.dev.inspect =~ /IO:<([^>]+)>/
            return $1
          end
        end
        return "Unknown Log Destination (#{logdev.inspect})"
      else
        logger
      end
    end
  end
end
