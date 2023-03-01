require 'spec_helper'

describe PaulBunyan::LogRelayer do
  let(:empty_relayer) { PaulBunyan::LogRelayer.new }

  let(:primary) { double('primary logger') }
  let(:single_relayer) do
    PaulBunyan::LogRelayer.new.tap do |relayer|
      relayer.add_logger(primary)
    end
  end

  let(:secondary) { double('secondary logger') }
  let(:double_relayer) do
    single_relayer.tap do |relayer|
      relayer.add_logger(secondary)
    end
  end

  let(:tertiary) { double('tertiary logger') }
  let(:triple_relayer) do
    double_relayer.tap do |relayer|
      relayer.add_logger(tertiary)
    end
  end

  describe '::new' do
    it 'with no parameters, creates an empty log relayer' do
      expect(empty_relayer.loggers).to be_empty
    end
  end

  describe '#primary_logger' do
    it 'matches the first value in #loggers' do
      expect(double_relayer.primary_logger).to eq(double_relayer.loggers.first)
    end

    it 'is nil if there are no loggers' do
      expect(empty_relayer.primary_logger).to eq(nil)
    end
  end

  describe '#secondary_loggers' do
    it 'includes all but the first value in #loggers' do
      expect(triple_relayer.secondary_loggers).to eq([secondary, tertiary])
      expect(triple_relayer.secondary_loggers).to eq(triple_relayer.loggers[1..-1])
    end

    it 'is an empty array if there are no loggers' do
      expect(empty_relayer.secondary_loggers).to eq([])
    end

    it 'is an empty array if there is a single logger' do
      expect(single_relayer.secondary_loggers).to eq([])
    end
  end

  describe '#add_logger' do
    it 'adds loggers to the end of the #loggers array' do
      empty_relayer.add_logger(primary)
      expect(empty_relayer.loggers).to contain_exactly(primary)
    end

    it 'sets #primary_logger when the first logger is added' do
      empty_relayer.add_logger(primary)
      expect(empty_relayer.primary_logger).to be(primary)
    end

    it 'adds to #secondary_loggers when additional loggers are added' do
      single_relayer.add_logger(secondary)
      expect(single_relayer.primary_logger).not_to be(secondary)
      expect(single_relayer.secondary_loggers).to include(secondary)
    end
  end

  describe '#remove_logger' do
    it 'removes loggers' do
      single_relayer.remove_logger(primary)
      expect(single_relayer.loggers).not_to include(primary)
    end

    it 'can remove the primary logger' do
      single_relayer.remove_logger(single_relayer.primary_logger)
      expect(single_relayer.primary_logger).to eq(nil)
    end

    it 'promotes another logger to primary when removing the primary' do
      double_relayer.remove_logger(primary)
      expect(double_relayer.primary_logger).to eq(secondary)
    end

    it 'removes secondary loggers' do
      triple_relayer.remove_logger(secondary)
      expect(triple_relayer.secondary_loggers).not_to include(secondary)
    end
  end

  describe '#add' do
    it 'delegates to all child loggers' do
      expect(primary).to receive(:add).with(Logger::FATAL, 'msg', 'progname').and_return(true)
      expect(secondary).to receive(:add).with(Logger::FATAL, 'msg', 'progname').and_return(true)
      double_relayer.add(Logger::FATAL, 'msg', 'progname')
    end

    it 'aggregates responses from all child loggers' do
      expect(primary).to receive(:add).and_return(true)
      expect(secondary).to receive(:add).and_return(false)
      expect(double_relayer.add(Logger::FATAL)).to eq(false)
    end

    it 'only calls the block given once' do
      allow(primary).to receive(:add).and_yield
      allow(secondary).to receive(:add).and_yield

      block = proc {}
      expect(block).to receive(:call).once
      double_relayer.add(Logger::FATAL, &block)
    end

    it 'passes a block to child loggers if a block was given' do
      expect(primary).to receive(:add) { |*, &b| expect(b).not_to be(nil) }
      single_relayer.add(Logger::FATAL) {}
    end

    it 'does not pass a block to child loggers if a block was not given' do
      expect(primary).to receive(:add) { |*, &b| expect(b).to be(nil) }
      single_relayer.add(Logger::FATAL)
    end
  end

  describe '#<<' do
    it 'delegates to all child loggers' do
      expect(primary).to receive(:<<).with('msg')
      expect(secondary).to receive(:<<).with('msg')

      double_relayer << 'msg'
    end

    it 'returns the lowest value returned by child loggers' do
      expect(primary).to receive(:<<).with('msg').and_return(3)
      expect(secondary).to receive(:<<).with('msg').and_return(1)
      expect(tertiary).to receive(:<<).with('msg').and_return(2)

      expect(triple_relayer << 'msg').to eq(1)
    end
  end

  describe '#debug' do
    it 'calls add with DEBUG severity' do
      block = proc {}
      expect(empty_relayer).to receive(:add).with(Logger::DEBUG, nil, 'progname') { |*, &b| expect(b).to eq(block) }
      empty_relayer.debug('progname', &block)
    end
  end

  describe '#info' do
    it 'calls add with INFO severity' do
      block = proc {}
      expect(empty_relayer).to receive(:add).with(Logger::INFO, nil, 'progname') { |*, &b| expect(b).to eq(block) }
      empty_relayer.info('progname', &block)
    end
  end

  describe '#warn' do
    it 'calls add with WARN severity' do
      block = proc {}
      expect(empty_relayer).to receive(:add).with(Logger::WARN, nil, 'progname') { |*, &b| expect(b).to eq(block) }
      empty_relayer.warn('progname', &block)
    end
  end

  describe '#error' do
    it 'calls add with ERROR severity' do
      block = proc {}
      expect(empty_relayer).to receive(:add).with(Logger::ERROR, nil, 'progname') { |*, &b| expect(b).to eq(block) }
      empty_relayer.error('progname', &block)
    end
  end

  describe '#fatal' do
    it 'calls add with FATAL severity' do
      block = proc {}
      expect(empty_relayer).to receive(:add).with(Logger::FATAL, nil, 'progname') { |*, &b| expect(b).to eq(block) }
      empty_relayer.fatal('progname', &block)
    end
  end

  describe '#unknown' do
    it 'calls add with UNKNOWN severity' do
      block = proc {}
      expect(empty_relayer).to receive(:add).with(Logger::UNKNOWN, nil, 'progname') { |*, &b| expect(b).to eq(block) }
      empty_relayer.unknown('progname', &block)
    end
  end

  describe '#level' do
    it 'returns the lowest level returned by child loggers' do
      expect(primary).to receive(:level).and_return(Logger::FATAL).at_least(:once)
      expect(secondary).to receive(:level).and_return(Logger::INFO).at_least(:once)
      expect(tertiary).to receive(:level).and_return(Logger::UNKNOWN).at_least(:once)

      expect(triple_relayer.level).to eq(Logger::INFO)
    end
  end

  context 'delegation' do
    let(:value) { double('value') }

    before do
      expect(double_relayer.primary_logger).to be(primary)
    end

    %i(
      progname
      sev_threshold
      formatter
      datetime_format
      close
      debug?
      info?
      warn?
      error?
      fatal?
    ).each do |m|
      describe "##{m}" do
        it 'delegates to the primary logger' do
          expect(primary).to receive(m).and_return(value)
          expect(secondary).not_to receive(m)
          expect(double_relayer.public_send(m)).to eq(value)
        end
      end
    end

    %i(
      progname=
      level=
      sev_threshold=
      formatter=
      datetime_format=
    ).each do |m|
      describe "##{m}" do
        it 'delegates to the primary logger' do
          expect(primary).to receive(m).with(value).and_return(value)
          expect(secondary).not_to receive(m)
          expect(double_relayer.public_send(m, value)).to eq(value)
        end
      end
    end
  end

  context 'silence' do
    describe '#silence' do
      it 'calls silence on all loggers' do
        expect(primary).to receive(:silence).with(Logger::WARN) { |&b| b.call }
        expect(secondary).to receive(:silence).with(Logger::WARN) { |&b| b.call }
        expect { |b| double_relayer.silence(Logger::WARN, &b) }.to yield_control
      end

      it 'skips loggers without a #silence method' do
        allow(secondary).to receive(:respond_to?) { false }
        expect(primary).to receive(:silence).with(Logger::WARN) { |&b| b.call }
        expect { |b| double_relayer.silence(Logger::WARN, &b) }.to yield_control
      end
    end
  end

  describe '#current_tags' do
    it 'aggregates the #current_tags of child loggers (skipping non-tagged loggers)' do
      expect(primary).to receive(:current_tags).and_return(%w(a b))
      expect(tertiary).to receive(:current_tags).and_return(%w(b c))
      expect(Set.new(triple_relayer.current_tags)).to be_superset(Set.new(%w(a b c)))
    end
  end

  describe '#push_tags' do
    it 'delegates to all child loggers' do
      expect(primary).to receive(:push_tags).with(*%w(a b c))
      expect(tertiary).to receive(:push_tags).with(*%w(a b c))
      triple_relayer.push_tags(*%w(a b c))
    end

    it 'flattens the tags list' do
      expect(primary).to receive(:push_tags).with(*%w(a b c d))
      single_relayer.push_tags(%w(a b), %w(c d))
    end

    it 'omits blank tags' do
      expect(primary).to receive(:push_tags).with(*%w(a b c d))
      single_relayer.push_tags(['a', 'b', '', nil, 'c', 'd'])
    end

    it 'returns the flattened, non-blank list of tags' do
      allow(primary).to receive(:push_tags)
      expect(single_relayer.push_tags(%w(a b), nil, '', %w(c d))).to eq(%w(a b c d))
    end
  end

  describe '#pop_tags' do
    it 'delegates to all child loggers' do
      expect(primary).to receive(:pop_tags).with(4)
      expect(tertiary).to receive(:pop_tags).with(4)
      triple_relayer.pop_tags(4)
    end
  end

  describe '#clear_tags!' do
    it 'delegates to all child loggers' do
      expect(primary).to receive(:clear_tags!)
      expect(secondary).to receive(:clear_tags!)
      triple_relayer.clear_tags!
    end
  end

  describe '#flush' do
    it 'delegates to all child loggers' do
      expect(primary).to receive(:flush)
      expect(secondary).to receive(:flush)
      triple_relayer.flush
    end
  end

  describe '#tagged' do
    it 'calls #push_tags with the given tags' do
      expect(single_relayer).to receive(:push_tags).with(*%w(a b c)).and_return(%w(a b c))
      expect { |b| single_relayer.tagged(*%w(a b c), &b) }.to yield_control
    end

    it 'calls #pop_tags with the number of tags returned from #push_tags' do
      expect(single_relayer).to receive(:push_tags).with('a', 'b', '', 'd').and_return(%w(a b c))
      expect(single_relayer).to receive(:pop_tags).with(3)
      single_relayer.tagged('a', 'b', '', 'd') {}
    end

    it 'calls #pop_tags when the block raises an exception' do
      expect(single_relayer).to receive(:pop_tags)
      expect { single_relayer.tagged('a') { fail StandardError, ':(' } }.to raise_error(StandardError)
    end
  end

  # The funny `, **({})` bit can be removed once we don't test on ruby 2.7
  # It ensures that the spec considers the arg to be a hash arg and not a kwarg
  # on ruby < 3.0.  The methods treat actual hashes and kwargs identically so
  # it doesn't really matter which one it passes through as
  context 'logging metadata' do
    let(:my_metadata) { {foo: 'bar'} }

    before do
      allow(primary).to receive(:respond_to?).and_return(true)
      allow(secondary).to receive(:respond_to?).and_return(false)
      allow(tertiary).to receive(:respond_to?).and_return(true)
    end

    describe '#add_metadata' do
      it 'delegates to all child loggers that support it' do
        expect(primary).to receive(:add_metadata).with(my_metadata)
        expect(secondary).to_not receive(:add_metadata)
        double_relayer.add_metadata(my_metadata, **({}))
      end
    end

    describe '#clear_metadata!' do
      it 'delegates to all child loggers' do
        expect(primary).to receive(:clear_metadata!)
        expect(secondary).to_not receive(:clear_metadata!)
        double_relayer.clear_metadata!
      end
    end

    describe '#current_metadata' do
      it 'aggregates the #current_metadata of child loggers (skipping non-metadata loggers)' do
        expect(primary).to receive(:current_metadata).and_return(foo: 'bar')
        expect(secondary).to_not receive(:current_metadata)
        expect(tertiary).to receive(:current_metadata).and_return(baz: 'qux')

        expect(triple_relayer.current_metadata).to eq(foo: 'bar', baz: 'qux')
      end
    end

    describe '#remove_metadata' do
      it 'delegates to all child loggers' do
        expect(primary).to receive(:remove_metadata).with(my_metadata)
        expect(secondary).to_not receive(:remove_metadata)
        double_relayer.remove_metadata(my_metadata, **({}))
      end
    end

    describe '#with_metadata' do
      before do
        allow(single_relayer).to receive(:add_metadata).with(my_metadata, **({}))
        allow(single_relayer).to receive(:remove_metadata).with(my_metadata, **({}))
      end

      it 'must call #add_metadata with the supplied hash' do
        expect(single_relayer).to receive(:add_metadata).with(my_metadata, **({}))
        expect { |b| single_relayer.with_metadata(my_metadata, **({}), &b) }.to yield_control
      end

      it 'must call #remove_metadata with the supplied hash' do
        expect(single_relayer).to receive(:remove_metadata).with(my_metadata, **({}))
        expect { |b| single_relayer.with_metadata(my_metadata, **({}), &b) }.to yield_control
      end

      it 'must call #remove_metadata when the block raises an exception' do
        expect(single_relayer).to receive(:remove_metadata).with(my_metadata, **({}))
        expect { single_relayer.with_metadata(my_metadata, **({})) do
          fail StandardError, ':('
        end
        }.to raise_error(StandardError)
      end
    end
  end
end
