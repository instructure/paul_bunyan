require "spec_helper"

describe Logging do
  describe 'when included in another class' do
    it 'must add the #logger method to the host' do
      klass = Class.new
      instance = klass.new

      expect(instance).to_not respond_to :logger

      klass.send(:include, Logging)
      expect(instance).to respond_to :logger
    end
  end

  describe ".logger" do
    it 'must build a logger writing to STDOUT when unset' do
      expect(Logging.logger.device.dev).to eq STDOUT
    end
  end

  describe ".set_logger" do
    it "accepts a Logger object" do
      logger = Logger.new(STDERR)
      Logging.set_logger(logger)
      desc1 = Logging::Device.describe(logger)
      desc2 = Logging::Device.describe(Logging.logger)
      expect(Logging.logger.description).to eq 'STDERR'
      expect(Logging.logger.logger).to eq logger
    end

    it "inherits a Logger object's level" do
      logger = Logger.new(STDERR)
      logger.level = ::Logger::FATAL
      Logging.set_logger(logger)
      expect(logger.level).to eq ::Logger::FATAL
      expect(Logging.logger.level).to eq ::Logger::FATAL
    end
  end
end
