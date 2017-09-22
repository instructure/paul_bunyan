# An example Rack middleware to capture the host the request was made to
require 'rack/request'

class HostMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if PaulBunyan.logger.respond_to?(:with_metadata)
      req = Rack::Request.new(env)

      PaulBunyan.logger.with_metadata(request_host: req.host) do
        @app.call(env)
      end
    else
      @app.call(env)
    end
  end
end
