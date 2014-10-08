require "spec_helper"

module Logging
  describe JSONFormatter do
    let(:formatter) { JSONFormatter.new }
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

      it "must include the supplied timestamp including microseconds" do
        output = formatter.call('', time, '', '')
        object = JSON.parse(output)
        parsed_time = Time.parse(object['ts'])
        expect(parsed_time.to_f).to eq time.to_f
      end

      it "must include the supplied progname argument as the program key" do
        output = formatter.call('', time, 'FooBar', '')
        object = JSON.parse(output)
        expect(object['program']).to eq 'FooBar'
      end

      it 'must include the current process id as the pid key' do
        output = formatter.call('', time, '', '')
        object = JSON.parse(output)
        expect(object['pid']).to eq $$
      end

      it 'must wrap a string message in an object with a message key containing the key' do
        output = formatter.call('', time, '', 'This is my message, there are many like it.')
        object = JSON.parse(output)
        expect(object['message']).to eq 'This is my message, there are many like it.'
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

        it 'must merge the hash with the base information' do
          expect(parsed_output['foo']).to eq 'bar'
        end

        it 'must protect the base attributes by adding a suffix to supplied keys that collide' do
          expect(parsed_output['ts_user']).to_not be nil
        end
      end

      context 'when supplied an exception object' do
        let(:exception) {
          begin
            raise StandardError, "This is my exception...."
          rescue StandardError
            exception = $!
          end
          exception
        }

        let(:output) { formatter.call('', time, '', exception) }
        let(:parsed_output) { JSON.parse(output) }

        it 'must include the exception class' do
          expect(parsed_output['class']).to eq 'StandardError'
        end

        it "must include the exception's message" do
          expect(parsed_output['message']).to eq 'This is my exception....'
        end

        it "must include the exception's backtrace" do
          expect(parsed_output['backtrace']).to eq exception.backtrace
        end
      end
    end
  end
end
