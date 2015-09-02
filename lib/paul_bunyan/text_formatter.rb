begin
  require 'active_support/tagged_logging'
rescue LoadError
end

module PaulBunyan
  class TextFormatter < Logger::Formatter
    include ActiveSupport::TaggedLogging::Formatter if defined?(ActiveSupport::TaggedLogging)

    def initialize(include_metadata: true)
      @include_metadata = include_metadata
    end

    def call(severity, time, progname, msg)
      message = (String === msg ? msg : msg.inspect)
      if @include_metadata
        super(severity, time, progname, message)
      else
        message + "\n"
      end
    end
  end
end
