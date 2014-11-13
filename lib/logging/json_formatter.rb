require "json"
require "term/ansicolor"

module Logging
  class JSONFormatter
    include Term::ANSIColor

    DATETIME_FORMAT = '%Y-%m-%dT%H:%M:%S.%6N %Z'
    SEVERITY_COLORS = Hash.new {|h, k|
      :white
    }.tap { |colors|
      colors['FATAL'] = :red
      colors['ERROR'] = :red
      colors['WARN'] = :yellow
      colors['DEBUG'] = :faint
    }

    def initialize(tty_output = false)
      @tty_output = tty_output
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
        message_data = format_message(msg)

        merge_metadata_and_message(metadata, message_data).to_json + "\n"
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
        class: exception.class.to_s,
        message: exception.message,
        backtrace: exception.backtrace,
      }
    end

    def format_string(message)
      { message: message }
    end

    def format_generic_object(object)
      if object.respond_to?(:to_h)
        object.to_h
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
          clean["#{ key }_user"] = value
        else
          clean[key] = value
        end
        clean
      }
    end

    def with_color(severity, &block)
      if @tty_output
        self.send(SEVERITY_COLORS[severity], &block)
      else
        yield
      end
    end
  end
end
