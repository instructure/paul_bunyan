require 'spec_helper'

initial_default_formatter_type = Logging.default_formatter_type

describe Logging do
  shared_examples 'respecting the ::default_formatter_type' do
    let(:logger) { double('logger') }

    before do
      allow(Logger).to receive(:new).and_return(logger)
    end

    it 'sets the default formatter to json, if set to :json' do
      Logging.default_formatter_type = :json
      expect(logger).to receive(:formatter=).with(instance_of(Logging::JSONFormatter))
      default_formatter_type_call
    end

    it 'sets the default formatter to text, if set to :text' do
      Logging.default_formatter_type = :text
      expect(logger).to receive(:formatter=).with(instance_of(Logging::TextFormatter))
      default_formatter_type_call
    end

    it 'does not modify the default formatter, if set to nil' do
      Logging.default_formatter_type = nil
      expect(logger).not_to receive(:formatter=)
      default_formatter_type_call
    end
  end

  before do
    # reset the Logging module before each test
    Logging.remove_instance_variable(:@logger) if Logging.instance_variable_defined?(:@logger)
    Logging.default_formatter_type = initial_default_formatter_type
  end

  describe 'include' do
    subject(:klass) { Class.new }
    subject(:logging_klass) { Class.new { include Logging } }

    it 'adds #logger to the host class' do
      expect(klass.new).not_to respond_to(:logger)
      expect(logging_klass.new).to respond_to(:logger)
    end
  end

  describe '::logger' do
    it 'instantiates a log relayer' do
      expect(Logging.logger).to be_a(Logging::LogRelayer)
    end

    it 'maintains a single instance' do
      logger = Logging.logger
      expect(Logging.logger).to be(logger)
    end

    it 'adds a default STDOUT logger' do
      expect(STDOUT).to receive(:write)
      Logging.logger << 'msg'
    end

    def default_formatter_type_call
      Logging.logger
    end

    it_behaves_like 'respecting the ::default_formatter_type'
  end

  describe '::create_logger' do
    let(:device) { double('device') }
    let(:logger) { double('logger') }

    before do
      allow(logger).to receive(:formatter=)
    end

    it 'creates a new logger and adds it to the log relayer' do
      expect(Logger).to receive(:new).with(device, 12, 42).and_return(logger)
      Logging.create_logger(device, 12, 42)
    end

    it 'returns the newly created logger' do
      expect(Logger).to receive(:new).and_return(logger)
      expect(Logging.create_logger(device)).to be(logger)
    end

    it 'allows the default formatter type to be overridden' do
      Logging.default_formatter_type = :json
      expect(Logger).to receive(:new).and_return(logger)
      expect(logger).to receive(:formatter=).with(instance_of(Logging::TextFormatter))
      Logging.create_logger(device, formatter_type: :text)
    end

    def default_formatter_type_call
      Logging.create_logger(device)
    end

    it_behaves_like 'respecting the ::default_formatter_type'
  end

  describe '::add_logger' do
    it 'adds the logger to the log relayer' do
      logger = double('logger')
      expect(Logging.logger).not_to be(nil)
      Logging.add_logger(logger)
      expect(Logging.logger.secondary_loggers).to include(logger)
    end

    it 'creates an empty log relayer, if not present' do
      logger = double('logger')
      Logging.add_logger(logger)
      expect(Logging.logger.loggers).to eq([logger])
    end

    it 'does not recreate the log relayer, if already present' do
      logger1 = double('logger1')
      logger2 = double('logger2')
      Logging.add_logger(logger1)
      Logging.add_logger(logger2)
      expect(Logging.logger.loggers).to include(logger1)
      expect(Logging.logger.loggers).to include(logger2)
    end

    it 'returns the logger added' do
      logger = double('logger')
      expect(Logging.add_logger(logger)).to be(logger)
    end
  end

  describe '::remove_logger' do
    it 'removes the logger from the log relayer' do
      expect(Logging.logger).to receive(:remove_logger).with(Logging.logger.primary_logger)
      Logging.remove_logger(Logging.logger.primary_logger)
    end
  end
end
