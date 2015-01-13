require "spec_helper"

describe Logging::IntrospectableLogger do
  let(:logger) { Logging::IntrospectableLogger.new }

  it "initializes" do
    expect { logger }.not_to raise_error
  end

  it "includes the magic instance variable" do
    variable = "@#{Logging::IntrospectableLogger::INTROSPECT_VAR}"
    expect(logger.instance_variable_get(variable)).to be_truthy
  end

  it "provides caller metadata" do
    var = {a: "some metadata", b: 2}
    md = logger.caller_metadata
    expect(md["local.var"]).to eq({:a => "some metadata", :b => 2})
    expect(md["caller.file"]).to match(/introspectable_logger_spec\.rb$/)
    expect(md["caller.line"]).to eq(__LINE__ - 3)
  end

  describe "#format_variables" do
    it "accepts name, value pairs" do
      vars = [["name", "value"]]
      result = Logging::IntrospectableLogger.format_variables(vars)
      expect(result).to eq({"name" => "value"})
    end
  end
end
