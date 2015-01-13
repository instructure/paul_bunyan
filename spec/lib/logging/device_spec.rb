require "spec_helper"

describe Logging::Device do
  context "#from" do
    let(:device) { Logging::Device.new }

    it "accepts a file handle" do
      expect(device.from(STDOUT)).to eq STDOUT
    end

    it "accepts a file" do
      expect(device.from("/tmp/app.log")).to eq "/tmp/app.log"
    end

    it "accepts a string representing STDOUT" do
      expect(device.from("stdout")).to eq STDOUT
      expect(device.from("STDOUT")).to eq STDOUT
    end

    it "accepts a string representing STDERR" do
      expect(device.from("stderr")).to eq STDERR
      expect(device.from("STDERR")).to eq STDERR
    end
  end

  context "#describe" do
    it "gets a filename" do
      device = Logging::Device.new("/tmp/file.log")
      expect(device.description).to eq "/tmp/file.log"
    end

    it "gets a device" do
      device = Logging::Device.new(STDOUT)
      expect(device.description).to eq "STDOUT"
    end
  end

  context "#with_temp_device" do
    before(:all) { require 'tempfile' }

    let(:device) { Logging::Device.new("/dev/null") }
    let(:tmpfile) { Tempfile.new("temp_device.log") }

    it "adds then removes the given device to the internal list of devices" do
      # Expect the device to get added
      device.with_temp_device(tmpfile) do
        expect(device.all_devices).to include(tmpfile)
      end
      # Expect it to be gone once the block finishes
      expect(device.all_devices).not_to include(tmpfile)
    end

    it "logs to the device" do
      expect(tmpfile).to receive(:write).with(kind_of(String))

      device.with_temp_device(tmpfile) do
        device.write("Foo!")
      end
    end

    it "re-raises and logs exceptions" do
      expect(tmpfile).to receive(:write).with(kind_of(String))

      expect {
        device.with_temp_device(tmpfile) do
          raise :this_is_an_error
        end
      }.to raise_error
    end

    after(:each) do
      tmpfile.unlink
    end
  end

end
