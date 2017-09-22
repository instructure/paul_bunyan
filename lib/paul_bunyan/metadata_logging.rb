module PaulBunyan
  module MetadataLogging
    def clear_metadata!
      formatter.clear_metadata!
    end

    def with_metadata(metadata)
      formatter.with_metadata(metadata) { yield self }
    end

    def flush
      clear_metadata!
      super if defined?(super)
    end
  end
end
