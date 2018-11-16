module PaulBunyan
  module MetadataLogging
    def clear_metadata!
      formatter.clear_metadata! if formatter.respond_to?(:clear_metadata!)
    end

    def with_metadata(metadata)
      if formatter.respond_to?(:with_metadata)
        formatter.with_metadata(metadata) { yield self }
      else
        yield self
      end
    end

    def add_metadata(metadata)
      formatter.add_metadata(metadata) if formatter.respond_to?(:add_metadata)
    end

    def remove_metadata(metadata)
      formatter.remove_metadata(metadata) if formatter.respond_to?(:remove_metadata)
    end

    def current_metadata
      if formatter.respond_to?(:current_metadata)
        return formatter.current_metadata
      else
        return {}
      end
    end

    def flush
      clear_metadata!
      super if defined?(super)
    end
  end
end
