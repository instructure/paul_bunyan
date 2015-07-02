require 'rails/rack/logger'

module Rails
  module Rack
    class Logger

      # This was copied directly from the rails source and had
      # the logging lines removed. N.B. this may break in future
      # versions of rails.
      def call_app(request, env)
        instrumenter = ActiveSupport::Notifications.instrumenter
        instrumenter.start 'request.action_dispatch', request: request
        resp = @app.call(env)
        resp[2] = ::Rack::BodyProxy.new(resp[2]) { finish(request) }
        resp
      rescue
        finish(request)
        raise
      ensure
        ActiveSupport::LogSubscriber.flush_all!
      end
    end
  end
end
