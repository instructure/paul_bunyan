require 'active_support/logger'

# Sad hax but ActiveRecord insists on using this method for console sessions
# and everything uses it in development causing us to get double log lines :-(
module ActiveSupport
  class Logger
    def self.broadcast(_)
      Module.new
    end
  end
end
