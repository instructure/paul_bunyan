require "spec_helper"

describe Logging do
  it "can be included" do
    include Logging::Logger
  end

  it "logger when uninited it goes to stdout" do
    expect(Logging.logger.instance_variable_get("@logdev").dev).to eq STDOUT
  end

  describe "#set_logger" do
    it "accepts a Logger object" do
      logger = Logger.new(STDERR)
      Logging.set_logger(logger)
      desc1 = Logging::Device.describe(logger)
      desc2 = Logging::Device.describe(Logging.logger)
      expect(desc1).to eq desc2
      expect(logger.level).to eq Logging.logger.level
    end

    it "inherits a Logger object's level" do
      logger = Logger.new(STDERR)
      logger.level = ::Logger::FATAL
      Logging.set_logger(logger)
      expect(logger.level).to eq ::Logger::FATAL
      expect(Logging.logger.level).to eq ::Logger::FATAL
    end
  end

  describe "#logger_description" do
    it "describes STDOUT" do
      Logging.set_logger('stdout')
      expect(Logging.logger_description).to eq("STDOUT")
    end
  end
end
