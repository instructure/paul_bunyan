require 'spec_helper'

describe PaulBunyan::MetadataLogging do
  subject { Object.new }
  let(:formatter) { double('formatter') }

  before do
    subject.extend(PaulBunyan::MetadataLogging)
    allow(subject).to receive(:formatter).and_return(formatter)
  end

  it 'must delegate clear_metadata! to the formatter' do
    expect(formatter).to receive(:clear_metadata!)
    subject.clear_metadata!
  end

  it 'must delegate with_metadata to the formatter' do
    expect(formatter).to receive(:with_metadata).with(foo: 'bar').and_yield
    subject.with_metadata(foo: 'bar') do |logger|
      expect(subject).to eq logger
    end
  end

  it 'must delegate add_metadata to the formatter' do
    expect(formatter).to receive(:add_metadata).with(foo: 'bar')
    subject.add_metadata(foo: 'bar')
  end

  it 'must delegate current_metadata to the formatter' do
    expect(formatter).to receive(:current_metadata).and_return({})
    subject.current_metadata
  end

  it 'must delegate remove_metadata to the formatter' do
    expect(formatter).to receive(:remove_metadata).with(foo: 'bar')
    subject.remove_metadata(foo: 'bar')
  end

  context '#flush' do
    it 'clears metadata on the formatter' do
      expect(formatter).to receive(:clear_metadata!)
      subject.flush
    end

    it 'sends flush to a parent' do
      klass = Class.new
      klass.class_eval do
        def flush
          flush_behavior()
        end
      end

      metadata_logger = klass.new
      metadata_logger.extend(PaulBunyan::MetadataLogging)
      allow(metadata_logger).to receive(:formatter).and_return(formatter)
      allow(formatter).to receive(:clear_metadata!)

      expect(metadata_logger).to receive(:flush_behavior)
      metadata_logger.flush
    end
  end
end
