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
