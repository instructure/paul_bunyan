module PaulBunyan
  module TaggedLogging
    def push_tags(*args)
      formatter.push_tags(*args)
    end

    def pop_tags(count = 1)
      formatter.pop_tags(count)
    end

    def clear_tags!
      formatter.clear_tags!
    end

    def tagged(*tags)
      formatter.tagged(*tags) { yield self }
    end

    def flush
      clear_tags!
      super if defined?(super)
    end
  end
end
