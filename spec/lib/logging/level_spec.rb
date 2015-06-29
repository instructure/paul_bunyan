require "spec_helper"

module Logging
  describe Level do

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
        expect{ Logging::Level.try_parse_integer_level('warn') }.to raise_error ArgumentError
      end
    end

    context "#try_parse_string_level" do
      it "accepts log level strings" do
        expect(Logging::Level.try_parse_string_level('debug')).to eq ::Logger::DEBUG
        %w(Fatal ERROR warn info DeBug).each do |level|
          Logging::Level.try_parse_string_level(level)
        end
      end

      it 'must accept symbols matching a valid level' do
        expect(Level.try_parse_string_level(:debug)).to eq ::Logger::DEBUG
      end

      it "rejects strings that are not log levels" do
        expect{ Logging::Level.try_parse_string_level('critical') }.to raise_error UnknownLevelError
      end
    end

    context "#parse_level" do
      it "accepts strings" do
        expect(Logging::Level.parse_level('error')).to eq ::Logger::ERROR
        expect(Logging::Level.parse_level('warn')).to eq ::Logger::WARN
      end
    end
  end
end
