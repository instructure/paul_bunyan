module Logging
  class TextFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
      if msg.is_a?(Hash)
        super(severity, time, progname, msg[:message])
      else
        super(severity, time, progname, msg)
      end
    end
  end
end
