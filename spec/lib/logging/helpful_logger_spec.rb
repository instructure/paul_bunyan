require "spec_helper"

module Logging
  describe HelpfulLogger do
    let(:logger) { HelpfulLogger.new }

    describe '#initialize(logdev, options = {})' do
      it 'must not fail when the level option is unset' do
        logger = HelpfulLogger.new(STDOUT)
      end
    end

    describe "#description" do
      it "describes STDOUT" do
        expect(logger.description).to eq("STDOUT")
      end
    end

    describe '#level=(value)' do
      it 'must set the level to DEBUG when passed nil' do
        logger.level = nil
        expect(logger.level).to eq Logger::DEBUG
      end

      it 'must set the level properly when passed an integer (or Logger level constant)' do
        logger.level = 3
        expect(logger.level).to eq Logger::ERROR
      end

      it 'must set the level properly when passed the string representation of an integer' do
        logger.level = '4'
        expect(logger.level).to eq Logger::FATAL
      end

      it 'must set the level properly when passed a lower case level string' do
        logger.level = 'warn'
        expect(logger.level).to eq Logger::WARN
      end

      it 'must raise a descriptive exception when passed a string that does not match a known level' do
        expect { logger.level = 'garbage level' }.to raise_error Logging::UnknownLevelError
      end
    end

    describe '#push_tags(*tags)' do
      before do
        logger.formatter = JSONFormatter.new(logger)
      end

      it 'must add tags to the formatter' do
        begin
          logger.push_tags(%w{foo bar baz})
          expect(logger.formatter.current_tags).to eq %w{foo bar baz}
        ensure
          logger.clear_tags!
        end
      end
    end
  end
end
