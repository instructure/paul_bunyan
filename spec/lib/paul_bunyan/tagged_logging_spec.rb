require 'spec_helper'

describe PaulBunyan::TaggedLogging do
  subject { Object.new }
  let(:formatter) { double('formatter') }

  before do
    subject.extend(PaulBunyan::TaggedLogging)
    allow(subject).to receive(:formatter).and_return(formatter)
  end

  it 'delegates #push_tags to #formatter' do
    expect(formatter).to receive(:push_tags).with('a','b','c')
    subject.push_tags('a', 'b', 'c')
  end

  it 'delegates #pop_tags to #formatter' do
    expect(formatter).to receive(:pop_tags).with(3)
    subject.pop_tags(3)
  end

  it 'delegates #clear_tags! to #formatter' do
    expect(formatter).to receive(:clear_tags!)
    subject.clear_tags!
  end

  it 'delegates #tagged to #formatter' do
    expect(formatter).to receive(:tagged).with('a','b','c').and_yield
    subject.tagged('a', 'b', 'c') do |logger|
      expect(subject).to eq logger
    end
  end

  context '#flush' do
    it 'clears tags on the formatter' do
      expect(formatter).to receive(:clear_tags!)
      subject.flush
    end

    it 'sends flush to a parent' do
      klass = Class.new
      klass.class_eval do
        def flush
          flush_behavior()
        end
      end

      tagged_logger = klass.new
      tagged_logger.extend(PaulBunyan::TaggedLogging)
      allow(tagged_logger).to receive(:formatter).and_return(formatter)
      allow(formatter).to receive(:clear_tags!)

      expect(tagged_logger).to receive(:flush_behavior)
      tagged_logger.flush
    end
  end
end
