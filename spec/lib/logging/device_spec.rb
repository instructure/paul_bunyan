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

end
