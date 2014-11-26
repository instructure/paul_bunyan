require 'forwardable'
require "binding_of_caller"

module Logging
  class IntrospectableLogger
    extend Forwardable

    INTROSPECT_VAR = "__i_am_the_logger_caller__"

    DEFAULT_OPTS = {
      shift_age: 0,
      shift_size: 1048576
    }

    def initialize(logdev = STDOUT, opts = {})
      # This is a very special variable that we assign in at this frame in the
      # stack so that we can later identify, via bindings and introspection,
      # where the log call originated (i.e. file, line number, and context)
      instance_variable_set(:"@#{INTROSPECT_VAR}", true)

      if logdev.is_a?(Logger)
        @logger = logdev
        self.device = Device.new(device, DEFAULT_OPTS.merge(opts))
      else
        @logger = Logger.new(nil)
        self.device = Device.new(logdev, DEFAULT_OPTS.merge(opts))
      end
    end

    attr_reader :logger

    def_delegators :@logger,
      :debug?, :info?, :warn?, :error?, :fatal?,
      :formatter, :formatter=,
      :level, :level=,
      :add, :<<, :close

    # Explicit call forwards so we can introspect call stack
    def debug(*args, &block);   @logger.debug(*args, &block);   end
    def info(*args, &block);    @logger.info(*args, &block);    end
    def warn(*args, &block);    @logger.warn(*args, &block);    end
    def error(*args, &block);   @logger.error(*args, &block);   end
    def fatal(*args, &block);   @logger.fatal(*args, &block);   end
    def unknown(*args, &block); @logger.unknown(*args, &block); end

    def device
      @logger.instance_variable_get("@logdev")
    end

    def device=(device)
      @logger.instance_variable_set("@logdev", device)
    end

    def description
      device.description
    end

    # We need to skip bindings that are related only to logging, and get to the
    # original caller binding so we can introspect the calling environment
    def original_binding
      bindings = call_stack_bindings
      _, index = bindings.reverse.each_with_index.find do |b, i|
        b.eval("instance_variables.find{ |ivar| ivar == :@#{INTROSPECT_VAR} }")
      end
      bindings[-index] if index
    end

    def call_stack_bindings(binding = binding)
      frame = 0
      [].tap do |stack|
        while true
          begin
            stack << binding.of_caller(frame)
            frame += 1
          rescue RuntimeError
            break
          end
        end
      end
    rescue
      []
    end

    def call_stack_trace
      call_stack_bindings.map do |b|
        b.eval("[__FILE__, __LINE__.to_s]").join(':')
      end
    end

    def caller_metadata
      if caller = original_binding
        locals = caller.eval("local_variables.map{ |v| ['local.' + v.to_s, (eval(v.to_s) rescue nil) ] }")
        ivars  = caller.eval("instance_variables.reject{ |v| v =~ /^@__/ }.map{ |v| [v.to_s, instance_variable_get(v)] }")
        basics = {
          "caller.file"  => (caller.eval("__FILE__") rescue nil),
          "caller.line"  => (caller.eval("__LINE__") rescue nil),
          "caller.class" => (caller.eval("Class === self ? self : self.class") rescue nil),
        }
        basics.
          merge(IntrospectableLogger.format_variables(locals)).
          merge(IntrospectableLogger.format_variables(ivars))
      else
        # Help diagnose why we couldn't get a binding
        {
          "call_stack_bindings" => call_stack_trace
        }
      end
    end

    def self.format_variables(vars)
      Hash[
        vars.map do |(name, value)|
          [name,
            case value
            when Exception
              [value.class.to_s, value.message] + value.backtrace
            else
              value
            end
          ]
        end
      ]
    end
  end
end