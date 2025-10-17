require "spec_helper"

RSpec.describe Whop::Token do
  it "raises on missing header" do
    expect { described_class.verify({}) }.to raise_error(Whop::Error)
  end
end


