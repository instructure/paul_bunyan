module PaulBunyan
  module MetadataLogging
    def clear_metadata!
      formatter.clear_metadata!
    end

    def with_metadata(metadata)
      formatter.with_metadata(metadata) { yield self }
    end

    def add_metadata(metadata)
      formatter.add_metadata(metadata)
    end

    def remove_metadata(metadata)
      formatter.remove_metadata(metadata)
    end

    def current_metadata
      formatter.current_metadata
    end

    def flush
      clear_metadata!
      super if defined?(super)
    end
  end
end
