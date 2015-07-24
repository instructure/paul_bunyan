require 'spec_helper'

module Logging
  RSpec.describe Railtie do
    describe '.unsubscribe_default_log_subscribers' do
      before do
        @action_controller_subscriber = ActiveSupport::LogSubscriber.subscribers.find{|s|
          s.class == ActionController::LogSubscriber
        }

        Railtie.unsubscribe_default_log_subscribers
      end

      after do
        # replace any subscriptions we may have blown away so the next test
        # can be assured of a clean slate
        ActionController::LogSubscriber.attach_to(
          :action_controller,
          @action_controller_subscriber
        )
      end

      it 'must remove the ActionController::LogSubscriber subscription to process_action' do
        expect(subscriber_classes_for('process_action.action_controller')).
          to_not include ActionController::LogSubscriber
      end

      it 'must leave the ActionController::LogSubscriber subscription to deep_munge.action_controller in place' do
        # I don't expect that we'll ever care to unsubcribe the logger
        # non-event so we'll use it as a check to ensure we don't
        # clobber all of the listeners, only the ones we care about
        expect(subscriber_classes_for('logger.action_controller')).
          to include ActionController::LogSubscriber
      end
    end
  end
end
