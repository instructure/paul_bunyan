require "logging"

describe Logging do
  it "can be included" do
    include Logging::Logger
  end

  it "logger when uninited it goes to stdout" do
    expect(Logging.logger.instance_variable_get("@logdev").dev).to eq STDOUT
  end
end