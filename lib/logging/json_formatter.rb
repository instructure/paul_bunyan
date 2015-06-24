require 'thread'
require 'json'
require 'term/ansicolor'

module Logging
  class JSONFormatter
    include Term::ANSIColor

    DATETIME_FORMAT = '%Y-%m-%dT%H:%M:%S.%3N'

    SEVERITY_COLORS = Hash.new {|h, k|
      :white
    }.tap { |colors|
      colors['FATAL'] = :red
      colors['ERROR'] = :red
      colors['WARN'] = :yellow
      colors['DEBUG'] = :faint
    }

    def initialize(logger, opts={})
      @logger = logger
      @opts = opts
    end

    def call(severity, time, progname, msg)
      with_color severity do
        metadata = {
          "ts"       => time.utc.strftime(DATETIME_FORMAT),
          "unix_ts"  => time.to_f,
          "severity" => severity,
          "pid"      => $$,
        }
        metadata['program'] = progname if progname
        metadata['tags'] = current_tags unless current_tags.empty?

        message_data = format_message(msg)

        JSON::generate(merge_metadata_and_message(metadata, message_data)) + "\n"
      end
    end

    def clear_tags!
      current_tags.clear
    end

    def current_tags
      thread_key = @thread_key ||= "logging_tagged_logging_tags:#{ Thread.current.object_id }"
      Thread.current[thread_key] ||= []
    end

    def datetime_format=(value)
      # intentional nop because the whole point of this formatter is
      # to have a consistent machine parsable format :-P
    end

    def datetime_format
      DATETIME_FORMAT
    end

    def pop_tags(count = 1)
      current_tags.pop(count)
    end

    def push_tags(*tags)
      tags.flatten.reject{|t| t.nil? || t.to_s.strip == '' }.tap do |clean_tags|
        current_tags.concat(clean_tags)
      end
    end

    def tagged(*tags)
      clean_tags = push_tags(tags)
      yield
    ensure
      pop_tags(clean_tags.size)
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
        "exception.message" => exception.message,
      }
    end

    def format_string(message)
      { "message" => uncolored(message.strip) }
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
      if use_color?
        self.send(SEVERITY_COLORS[severity], &block)
      else
        yield
      end
    end

    def use_color?
      @opts.has_key?(:color) ? @opts[:color] : tty?
    end

    def tty?
      @logger && @logger.device.tty?
    end
  end
end
