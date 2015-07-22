require 'spec_helper'

describe Logging::Level do
  describe '::coerce_level' do
    it 'accepts integers', :aggregate_failures do
      (0..5).each do |level|
        aggregate_failures do
          expect(Logging::Level.coerce_level(level)).to eq(level)
        end
      end
    end

    it 'rejects integers that are out-of-range', :aggregate_failures do
      expect { Logging::Level.coerce_level(-1) }.to raise_error(Logging::UnknownLevelError)
      expect { Logging::Level.coerce_level(6) }.to raise_error(Logging::UnknownLevelError)
    end

    it 'accepts integer strings', :aggregate_failures do
      (0..5).each do |level|
        aggregate_failures do
          expect(Logging::Level.coerce_level(level.to_s)).to eq(level)
        end
      end
    end

    it 'rejects integer strings that are out-of-range', :aggregate_failures do
      expect { Logging::Level.coerce_level(-1) }.to raise_error(Logging::UnknownLevelError)
      expect { Logging::Level.coerce_level(6) }.to raise_error(Logging::UnknownLevelError)
    end

    it 'accepts integer strings with whitespace', :aggregate_failures do
      (0..5).each do |level|
        aggregate_failures do
          expect(Logging::Level.coerce_level(" \t#{level}")).to eq(level)
          expect(Logging::Level.coerce_level("#{level} \t")).to eq(level)
        end
      end
    end

    it 'accepts log level strings', :aggregate_failures do
      {
        'DeBug' => Logger::DEBUG,
        'Info' => Logger::INFO,
        'warn' => Logger::WARN,
        'ERROR' => Logger::ERROR,
        'FataL' => Logger::FATAL,
        'uNKNOWn' => Logger::UNKNOWN
      }.each do |k, v|
        aggregate_failures do
          expect(Logging::Level.coerce_level(k)).to eq(v)
        end
      end
    end

    it 'rejects invalid log level strings' do
      expect { Logging::Level.coerce_level('critical') }.to raise_error(Logging::UnknownLevelError)
    end

    it 'accepts log level symbols', :aggregate_failures do
      {
        DeBug: Logger::DEBUG,
        Info: Logger::INFO,
        warn: Logger::WARN,
        ERROR: Logger::ERROR,
        FataL: Logger::FATAL,
        uNKNOWn: Logger::UNKNOWN
      }.each do |k, v|
        aggregate_failures do
          expect(Logging::Level.coerce_level(k)).to eq(v)
        end
      end
    end

    it 'rejects invalid log level symbols' do
      expect { Logging::Level.coerce_level(:critical) }.to raise_error(Logging::UnknownLevelError)
    end
  end
end
