require 'json'
require 'thread'

module PaulBunyan
  class JSONFormatter
    DATETIME_FORMAT = '%Y-%m-%dT%H:%M:%S.%3N'

    def call(severity, time, progname, msg)
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
        'exception.class' => exception.class.to_s,
        'exception.backtrace' => exception.backtrace,
        'exception.message' => exception.message
      }.tap do |exception_hash|
        exception_hash['exception.cause'] = format_exception_cause(exception.cause) if exception.cause
      end
    end

    def format_exception_cause(cause)
      return format_exception(cause) if cause.is_a?(Exception)

      if cause.respond_to?(:to_str)
        cause.to_str
      elsif cause.respond_to?(:to_s)
        cause.to_s
      else
        cause.inspect
      end
    end

    def format_string(message)
      { 'message' => PaulBunyan.strip_ansi(message) }
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
  end
end
