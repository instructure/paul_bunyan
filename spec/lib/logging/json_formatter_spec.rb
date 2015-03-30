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
  end
end
