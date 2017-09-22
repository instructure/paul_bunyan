require 'spec_helper'

initial_default_formatter_type = PaulBunyan.default_formatter_type

describe PaulBunyan do
  shared_examples 'respecting the ::default_formatter_type' do
    let(:logger) { double('logger', formatter: nil) }

    before do
      allow(Logger).to receive(:new).and_return(logger)
    end

    it 'sets the default formatter to json, if set to :json' do
      PaulBunyan.default_formatter_type = :json
      expect(logger).to receive(:formatter=).with(instance_of(PaulBunyan::JSONFormatter))
      default_formatter_type_call
    end

    it 'sets the default formatter to text, if set to :text' do
      PaulBunyan.default_formatter_type = :text
      expect(logger).to receive(:formatter=).with(instance_of(PaulBunyan::TextFormatter))
      default_formatter_type_call
    end

    it 'does not modify the default formatter, if set to nil' do
      PaulBunyan.default_formatter_type = nil
      expect(logger).not_to receive(:formatter=)
      default_formatter_type_call
    end
  end

  before do
    # reset the PaulBunyan module before each test
    PaulBunyan.remove_instance_variable(:@logger) if PaulBunyan.instance_variable_defined?(:@logger)
    PaulBunyan.default_formatter_type = initial_default_formatter_type
  end

  describe 'include' do
    subject(:klass) { Class.new }
    subject(:logging_klass) { Class.new { include PaulBunyan } }

    it 'adds #logger to the host class' do
      expect(klass.new).not_to respond_to(:logger)
      expect(logging_klass.new).to respond_to(:logger)
    end
  end

  describe '::logger' do
    it 'instantiates a log relayer' do
      expect(PaulBunyan.logger).to be_a(PaulBunyan::LogRelayer)
    end

    it 'maintains a single instance' do
      logger = PaulBunyan.logger
      expect(PaulBunyan.logger).to be(logger)
    end

    it 'adds a default STDOUT logger' do
      expect(STDOUT).to receive(:write)
      PaulBunyan.logger << 'msg'
    end

    def default_formatter_type_call
      PaulBunyan.logger
    end

    it_behaves_like 'respecting the ::default_formatter_type'
  end

  describe '::create_logger' do
    let(:device) { double('device') }
    let(:logger) { double('logger', formatter: nil) }

    before do
      allow(logger).to receive(:formatter=)
    end

    it 'creates a new logger and adds it to the log relayer' do
      expect(Logger).to receive(:new).with(device, 12, 42).and_return(logger)
      PaulBunyan.create_logger(device, 12, 42)
    end

    it 'returns the newly created logger' do
      expect(Logger).to receive(:new).and_return(logger)
      expect(PaulBunyan.create_logger(device)).to be(logger)
    end

    it 'allows the default formatter type to be overridden' do
      PaulBunyan.default_formatter_type = :json
      expect(Logger).to receive(:new).and_return(logger)
      expect(logger).to receive(:formatter=).with(instance_of(PaulBunyan::TextFormatter))
      PaulBunyan.create_logger(device, formatter_type: :text)
    end

    it 'creates a logger capable of tagging when using formatter that is capable of tagging' do
      allow(logger).to receive(:formatter).and_return(double('formatter', tagged:nil))
      allow(Logger).to receive(:new).and_return(logger)
      PaulBunyan.create_logger(device)

      expect(logger.formatter).to respond_to(:tagged)
      expect(logger).to be_kind_of(PaulBunyan::TaggedLogging)
    end

    it 'must create a logger capable of handling metadata when using a formatter capable of handling metadata' do
      allow(logger).to receive(:formatter).and_return(double('formatter', with_metadata:nil))
      allow(Logger).to receive(:new).and_return(logger)
      PaulBunyan.create_logger(device)

      expect(logger.formatter).to respond_to(:with_metadata)
      expect(logger).to be_kind_of(PaulBunyan::MetadataLogging)
    end

    it 'creates a regular logger when using formatter that is not capable of tagging' do
      allow(Logger).to receive(:new).and_return(logger)
      PaulBunyan.create_logger(device)

      expect(logger.formatter).to_not respond_to(:tagged)
      expect(logger).to_not be_kind_of(PaulBunyan::TaggedLogging)
    end

    def default_formatter_type_call
      PaulBunyan.create_logger(device)
    end

    it_behaves_like 'respecting the ::default_formatter_type'
  end

  describe '::add_logger' do
    it 'adds the logger to the log relayer' do
      logger = double('logger')
      expect(PaulBunyan.logger).not_to be(nil)
      PaulBunyan.add_logger(logger)
      expect(PaulBunyan.logger.secondary_loggers).to include(logger)
    end

    it 'creates an empty log relayer, if not present' do
      logger = double('logger')
      PaulBunyan.add_logger(logger)
      expect(PaulBunyan.logger.loggers).to eq([logger])
    end

    it 'does not recreate the log relayer, if already present' do
      logger1 = double('logger1')
      logger2 = double('logger2')
      PaulBunyan.add_logger(logger1)
      PaulBunyan.add_logger(logger2)
      expect(PaulBunyan.logger.loggers).to include(logger1)
      expect(PaulBunyan.logger.loggers).to include(logger2)
    end

    it 'returns the logger added' do
      logger = double('logger')
      expect(PaulBunyan.add_logger(logger)).to be(logger)
    end
  end

  describe '::remove_logger' do
    it 'must not blow up when the logger has not been set' do
      PaulBunyan.instance_variable_set(:@logger, nil)
      PaulBunyan.remove_logger('nxlogger')
    end

    it 'removes the logger from the log relayer' do
      expect(PaulBunyan.logger).to receive(:remove_logger).with(PaulBunyan.logger.primary_logger)
      PaulBunyan.remove_logger(PaulBunyan.logger.primary_logger)
    end
  end

  describe '::strip_ansi' do
    it 'removes ANSI color codes' do
      expect(PaulBunyan.strip_ansi("\e[36;46mcolored message!")).to eq 'colored message!'
    end
  end
end
