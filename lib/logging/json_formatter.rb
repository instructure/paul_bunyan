require "json"
require "term/ansicolor"

module Logging
  class JSONFormatter
    include Term::ANSIColor

    DATETIME_FORMAT = '%Y-%m-%dT%H:%M:%S.%6N %Z'

    SERIOUS_LEVELS = %w{WARN ERROR FATAL}

    SEVERITY_COLORS = Hash.new {|h, k|
      :white
    }.tap { |colors|
      colors['FATAL'] = :red
      colors['ERROR'] = :red
      colors['WARN'] = :yellow
      colors['DEBUG'] = :faint
    }

    def initialize(logger)
      @logger = logger
    end

    def datetime_format=(value)
      # intentional nop because the whole point of this formatter is
      # to have a consistent machine parsable format :-P
    end

    def datetime_format
      DATETIME_FORMAT
    end

    def call(severity, time, progname, msg)
      with_color severity do
        metadata = {
          "ts"       => time.utc.strftime(DATETIME_FORMAT),
          "severity" => severity,
          "pid"      => $$,
        }
        metadata['program'] = progname if progname

        if @logger.respond_to?(:caller_metadata) && serious?(severity)
          c_metadata = @logger.caller_metadata
        else
          c_metadata = {}
        end

        message_data = format_message(msg)

        begin
          JSON::generate(merge_metadata_and_message(metadata.merge(c_metadata), message_data), max_nesting: 10) + "\n"
        rescue JSON::NestingError, SystemStackError => e
          JSON::generate(merge_metadata_and_message(metadata.merge(e.class.name => e), message_data)) + "\n"
        end
      end
    end

    private

    # TODO: extract all of this formatting/merging out into another class if it grows
    def format_message(message)
      case message
      when Exception
        format_exception(message)
      when String
        format_string(message)
      else
        format_generic_object(message)
      end
    end

    def format_exception(exception)
      {
        "exception.class" => exception.class.to_s,
        "exception.backtrace" => exception.backtrace,
        "message" => exception.message,
      }
    end

    def format_string(message)
      { "message" => message }
    end

    def format_generic_object(object)
      if object.respond_to?(:to_h)
        object.to_h
      elsif object.respond_to?(:to_hash)
        object.to_hash
      else
        format_string(object.inspect)
      end
    end

    def merge_metadata_and_message(metadata, message)
      clean_message = sanitize_message_keys(message, metadata.keys)
      metadata.merge(clean_message)
    end

    def sanitize_message_keys(message, metadata_keys)
      message.inject({}) { |clean, (key, value)|
        key = key.to_s
        if metadata_keys.include?(key)
          clean["user.#{ key }"] = value
        else
          clean[key] = value
        end
        clean
      }
    end

    def with_color(severity, &block)
      if tty?
        self.send(SEVERITY_COLORS[severity], &block)
      else
        yield
      end
    end

    def serious?(severity)
      SERIOUS_LEVELS.include?(severity)
    end

    def tty?
      @logger && @logger.device.tty?
    end
  end
end
