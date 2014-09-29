require "logging/level"

describe Logging::Level do

  context "#try_parse_integer_level" do
    it "accepts integers" do
      expect(Logging::Level.try_parse_integer_level(0)).to eq 0
      expect(Logging::Level.try_parse_integer_level(1)).to eq 1
    end

    it "accepts integer strings" do
      expect(Logging::Level.try_parse_integer_level('0')).to eq 0
      expect(Logging::Level.try_parse_integer_level('1')).to eq 1
    end

    it "rejects non-integer strings" do
      expect{ Logging::Level.try_parse_integer_level('warn') }.to raise_error
    end
  end

  context "#try_parse_string_level" do
    it "accepts log level strings" do
      expect(Logging::Level.try_parse_string_level('debug')).to eq ::Logger::DEBUG
      %w(Fatal ERROR warn info DeBug).each do |level|
        expect{ Logging::Level.try_parse_string_level(level) }.to_not raise_error
      end
    end

    it "rejects strings that are nog log levels" do
      expect{ Logging::Level.try_parse_string_level('critical') }.to raise_error
    end
  end

  context "#parse_level" do
    it "accepts strings" do
      expect(Logging::Level.parse_level('error')).to eq ::Logger::ERROR
      expect(Logging::Level.parse_level('warn')).to eq ::Logger::WARN
    end

  end

end