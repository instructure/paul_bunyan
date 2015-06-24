require "spec_helper"
require "time"

module Logging
  describe JSONFormatter do
    let(:formatter) { JSONFormatter.new(nil) }
    let(:time) { Time.new(2015, 2, 7, 13, 52, 3.141592) }

    describe "#call(severity, time, progname, msg)" do
      it "must return an object seralized as JSON" do
        output = formatter.call('', time, '', '')
        expect(JSON.parse(output)).to be_a Hash
      end

      it "must include the supplied severity string in the output" do
        output = formatter.call('WARN', time, '', '')
        object = JSON.parse(output)
        expect(object['severity']).to eq 'WARN'
      end

      it "must include the supplied timestamp including miliseconds" do
        output = formatter.call('', time, '', '')
        object = JSON.parse(output)
        expect(object['ts']).to eq time.strftime('%Y-%m-%dT%H:%M:%S.%3N')
      end

      it "must include a high resolution unix timestamp in as the unix_ts key" do
        output = formatter.call('', time, '', '')
        object = JSON.parse(output)
        expect(object['unix_ts']).to eq time.to_f
      end

      it "must include the supplied progname argument as the program key" do
        output = formatter.call('', time, 'FooBar', '')
        object = JSON.parse(output)
        expect(object['program']).to eq 'FooBar'
      end

      it "must include the current process id as the pid key" do
        output = formatter.call('', time, '', '')
        object = JSON.parse(output)
        expect(object['pid']).to eq $$
      end

      it "must wrap a string message in an object with a message key containing the key" do
        output = formatter.call('', time, '', 'This is my message, there are many like it.')
        object = JSON.parse(output)
        expect(object['message']).to eq 'This is my message, there are many like it.'
      end

      it 'must not include the tags array when none are set' do
        output = formatter.call('', time, '', 'This is my message, there are many like it.')
        object = JSON.parse(output)
        expect(object['tags']).to be_nil
      end

      it 'must include the tags array when some are set' do
        formatter.tagged(%w{foo bar}) do
          output = formatter.call('', time, '', 'This is my message, there are many like it.')
          object = JSON.parse(output)
          expect(object['tags']).to eq %w{foo bar}
        end
      end

      context 'when supplied a Hash' do
        let(:logged_hash) {
          {
            foo: 'bar',
            ts: 'baz',
          }
        }

        let(:output) { formatter.call('', time, '', logged_hash) }
        let(:parsed_output) { JSON.parse(output) }

        it "must merge the hash with the base information" do
          expect(parsed_output['foo']).to eq 'bar'
        end

        it "must protect the base attributes by prefixing 'user' to supplied keys that collide" do
          expect(parsed_output['user.ts']).to_not be nil
        end
      end

      context "when supplied an exception object" do
        let(:exception) {
          begin raise StandardError, "This is my exception...."
          rescue; exception = $!; end
          exception
        }
        let(:output) { formatter.call('', time, '', exception) }
        let(:parsed_output) { JSON.parse(output) }

        it "must include the exception class" do
          expect(parsed_output['exception.class']).to eq 'StandardError'
        end

        it "must include the exception's message" do
          expect(parsed_output['exception.message']).to eq 'This is my exception....'
        end

        it "must include the exception's backtrace" do
          expect(parsed_output['exception.backtrace']).to eq exception.backtrace
        end
      end
    end

    describe '#clear_tags!' do
      it 'must not fail when no tags have been set' do
        formatter.clear_tags!
      end

      it 'must remove all tags that have been set' do
        formatter.current_tags << 'foo'
        expect(formatter.current_tags).to_not be_empty
        formatter.clear_tags!
        expect(formatter.current_tags).to be_empty
      end
    end

    describe '#pop_tags(count = 1)' do
      before do
        formatter.push_tags %w{foo bar baz qux}
      end

      after do
        formatter.clear_tags!
      end

      it 'must default to removing the last tag added' do
        formatter.pop_tags
        expect(formatter.current_tags).to_not include 'qux'
      end

      it 'must pop the specified number of tags' do
        formatter.pop_tags(3)
        expect(formatter.current_tags).to eq %w{foo}
      end
    end

    describe '#push_tags(*tags)' do
      after do
        formatter.clear_tags!
      end

      it 'must add a single tag to the tags array' do
        formatter.push_tags('foo')
        expect(formatter.current_tags).to include 'foo'
      end

      it 'must add multiple tags to the current tags array' do
        formatter.push_tags 'foo', 'bar', :baz
        expect(formatter.current_tags).to contain_exactly 'foo', 'bar', :baz
      end

      it 'must add an array of tags to the current tags array' do
        formatter.push_tags %w{foo bar baz}
        expect(formatter.current_tags).to contain_exactly 'foo', 'bar', 'baz'
      end

      it 'must reject any tags that are nil' do
        formatter.push_tags('foo', 'bar', nil, 'qux')
        expect(formatter.current_tags).to contain_exactly 'foo', 'bar', 'qux'
      end

      it 'must reject any tags that are empty strings' do
        formatter.push_tags('foo', '', 'bar')
        expect(formatter.current_tags).to contain_exactly 'foo', 'bar'
      end
    end

    describe '#tagged(*tags)' do
      after do
        formatter.clear_tags!
      end

      it 'must yeild to the supplied block' do
        block_called = false
        formatter.tagged(%w{foo bar}) do
          block_called = true
        end
        expect(block_called).to eq true
      end

      it 'must set add the passed tags to the current tags array' do
        formatter.tagged(%w{bar baz}) do
          expect(formatter.current_tags).to eq %w{bar baz}
        end
      end

      it 'must remove the set tags after the block has executed' do
        formatter.tagged(%w{bar baz}) do
          # nop
        end
        expect(formatter.current_tags).to be_empty
      end

      it 'must not remove tags set before the call to tagged' do
        formatter.push_tags(%w{foo bar})
        formatter.tagged(%w{baz qux}) do
          expect(formatter.current_tags).to eq %w{foo bar baz qux}
        end
        expect(formatter.current_tags).to eq %w{foo bar}
      end

      it 'must remove the added tags even when an exception is raised in the block' do
        begin
          formatter.tagged(%w{baz qux}) do
            raise 'oh noes!'
          end
        rescue
        end
        expect(formatter.current_tags).to be_empty
      end
    end
  end
end
