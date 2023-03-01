require 'forwardable'
require 'set'

module PaulBunyan
  class LogRelayer
    extend Forwardable

    # delegate non-relayed methods to the primary logger
    DELEGATED_METHODS = %i(
      progname        progname=
      level           level=
      sev_threshold   sev_threshold=

      formatter       formatter=
      datetime_format datetime_format=

      close

      debug? info? warn? error? fatal?
    )
    delegate DELEGATED_METHODS => :primary_logger

    include Logger::Severity

    attr_reader :loggers

    def primary_logger
      loggers[0]
    end

    def secondary_loggers
      loggers[1..-1] || []
    end

    def add_logger(logger)
      loggers.push(logger)

      # Appease rails checking if logger already writes to stdout
      if loggers.length == 1
        @logdev = loggers[0].instance_variable_get(:@logdev)
      end
      logger
    end

    def remove_logger(logger)
      loggers.delete(logger)
    end

    def initialize
      @loggers = []
    end

    def add(severity, message = nil, progname = nil, &block)
      block = memoized_block(&block) if block
      loggers.reduce(true) do |memo, logger|
        logger.add(severity, message, progname, &block) && memo
      end
    end
    alias_method :log, :add

    def <<(msg)
      loggers.reduce(nil) do |memo, logger|
        n = logger << msg

        # this would be simpler with an array, but would generate unnecessary garbage
        if memo.nil? || n.nil?
          memo || n
        else
          memo < n ? memo : n
        end
      end
    end

    def debug(progname = nil, &block)
      add(DEBUG, nil, progname, &block)
    end

    def info(progname = nil, &block)
      add(INFO, nil, progname, &block)
    end

    def warn(progname = nil, &block)
      add(WARN, nil, progname, &block)
    end

    def error(progname = nil, &block)
      add(ERROR, nil, progname, &block)
    end

    def fatal(progname = nil, &block)
      add(FATAL, nil, progname, &block)
    end

    def unknown(progname = nil, &block)
      add(UNKNOWN, nil, progname, &block)
    end

    def level
      logger = loggers.min { |a, b| a.level <=> b.level }
      logger.nil? ? DEBUG : logger.level
    end

    def silence(level = Logger::ERROR, &block)
      loggers = self.loggers.select { |l| l.respond_to?(:silence) }.reverse
      silencer = proc do
        logger = loggers.pop
        if logger
          logger.silence(level, &silencer)
        else
          block.call
        end
      end
      silencer.call
    end

    def current_tags
      tags = loggers.each_with_object(Set.new) do |logger, set|
        set.merge(logger.current_tags) if logger.respond_to?(:current_tags)
      end
      tags.to_a
    end

    def push_tags(*tags)
      tags.flatten.reject(&:blank?).tap do |new_tags|
        messaging_loggers(:push_tags, *new_tags)
      end
    end

    def pop_tags(size = 1)
      messaging_loggers(:pop_tags, size)
    end

    def clear_tags!
      messaging_loggers(:clear_tags!)
    end

    def flush
      messaging_loggers(:flush)
    end

    def tagged(*tags)
      new_tags = push_tags(*tags)
      yield self
    ensure
      pop_tags(new_tags.size)
    end

    def add_metadata(metadata = {}, **kw_metadata)
      messaging_loggers(:add_metadata, metadata, **kw_metadata)
    end

    def clear_metadata!
      messaging_loggers(:clear_metadata!)
    end

    def current_metadata
      loggers.inject({}) do |agg, logger|
        if logger.respond_to?(:current_metadata)
          agg.merge(logger.current_metadata)
        else
          agg
        end
      end
    end

    def remove_metadata(metadata = {}, **kw_metadata)
      messaging_loggers(:remove_metadata, metadata, **kw_metadata)
    end

    def with_metadata(metadata = {}, **kw_metadata)
      add_metadata(metadata, **kw_metadata)
      yield
    ensure
      remove_metadata(metadata, **kw_metadata)
    end

    private

    def memoized_block(&block)
      called = false
      result = nil
      proc do
        next result if called
        called = true
        result = block.call
      end
    end

    def messaging_loggers(required_method, *args, **kwargs)
      loggers.each do |l|
        next unless l.respond_to?(required_method)

        # TODO remove this if and just always use the second branch once we only support
        # ruby 3.0+ (and remove 2.7).  Only matters for matchers in specs that natively
        # work correctly on ruby 3.0
        if kwargs.empty?
          l.public_send(required_method, *args)
        else
          l.public_send(required_method, *args, **kwargs)
        end         
      end
      nil
    end
  end
end
