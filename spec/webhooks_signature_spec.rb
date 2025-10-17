require "spec_helper"

RSpec.describe Whop::Webhooks::Signature do
  it "computes and validates signature" do
    secret = "shhh"
    payload = { action: "payment.succeeded", data: { id: "pay_1" } }.to_json
    sig = described_class.compute(secret, payload)
    expect(described_class.valid?(secret, payload, sig)).to be true
    expect(described_class.valid?(secret, payload, "sha256=#{sig}")).to be true
    expect(described_class.valid?(secret, payload, "bad")).to be false
  end
end


