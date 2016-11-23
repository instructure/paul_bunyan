require 'spec_helper'

RSpec.describe ActionController::Base do
  let(:request_id) { '5ab8b021-71bf-40f9-97cc-136f7b626a66' }

  around :each do |example|
    begin
      original_logger = PaulBunyan.logger.primary_logger
      null_logger = Logger.new('/dev/null')
      PaulBunyan.add_logger(null_logger)
      PaulBunyan.remove_logger(original_logger)

      example.run
    ensure
      PaulBunyan.add_logger(original_logger)
      PaulBunyan.remove_logger(null_logger)
    end
  end

  before :each do
    subject.request = ActionDispatch::TestRequest.new({
      'action_dispatch.request_id' => request_id,
      'REMOTE_ADDR' => '127.0.0.1',
    })
    subject.response = ActionDispatch::TestResponse.new

    def subject.index(*args)
      head :ok
    end
  end


  describe '.process_action(*args)' do
    context 'active support notification events' do
      before do
        allow(ActiveSupport::Notifications).to receive(:instrument)
      end

      it 'must emit a start_processing event in the action_controller namespace' do
        subject.send(:process_action, :index)
        expect(ActiveSupport::Notifications).to have_received(:instrument).
          with('start_processing.action_controller', anything).once
      end

      it 'must emit a process_action event in the action_controller namespace' do
        subject.send(:process_action, :index)
        expect(ActiveSupport::Notifications).to have_received(:instrument).
          with('process_action.action_controller', anything).once
      end
    end

    it 'must include the original rails payload keys in the event payload' do
      calling_index do |*args|
        payload = args.last
        expect(payload.keys).to include(
          *[:controller, :action, :params, :format, :method, :path]
        )
      end
    end

    it 'must add the request id to the notification payload hash' do
      calling_index do |*args|
        payload = args.last
        expect(payload).to include request_id: request_id
      end
    end

    it 'must add the request ip address to the notification payload' do
      calling_index do |*args|
        payload = args.last
        expect(payload).to include ip: '127.0.0.1'
      end
    end

    context 'with sensitive info in the query params' do
      before do
        subject.request = ActionDispatch::TestRequest.new({
          'action_dispatch.parameter_filter' => [:password, :baz],
          'PATH_INFO' => '/somewhere',
          'QUERY_STRING' => 'password=foo&bar=baz&baz=qux',
        })
      end

      it 'filters the sensitive params' do
        calling_index do |*args|
          payload = args.last
          expect(payload).to include path: '/somewhere?password=[FILTERED]&bar=baz&baz=[FILTERED]'
        end
      end
    end
  end

  def calling_index(&block)
    with_subscription_to('process_action.action_controller', block) do
      subject.send(:process_action, :index)
    end
  end
end
