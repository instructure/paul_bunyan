require 'action_controller/metal/instrumentation'

module ActionController
  module Instrumentation
    def process_action(*args)
      raw_payload = base_payload.merge(custom_payload)

      ActiveSupport::Notifications.instrument('start_processing.action_controller', raw_payload.dup)

      ActiveSupport::Notifications.instrument('process_action.action_controller', raw_payload) do |payload|
        begin
          result = super
          payload[:status] = response.status
          result
        ensure
          append_info_to_payload(payload)
        end
      end
    end

    private

    def base_payload
      {
        controller: self.class.name,
        action: self.action_name,
        params: request.filtered_parameters,
        format: request.format.try(:ref),
        method: request.request_method,
        path: (request.fullpath rescue 'unknown'),
      }
    end

    def custom_payload
      {
        request_id: request.env['action_dispatch.request_id'],
        ip: request.ip,
      }
    end
  end
end
