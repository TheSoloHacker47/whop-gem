require "spec_helper"

RSpec.describe Whop::Client do
  let(:config) { OpenStruct.new(api_base_url: "https://api.whop.com", api_key: "sk_", agent_user_id: nil, company_id: nil) }
  subject(:client) { described_class.new(config) }

  it "maps 404 to NotFoundError" do
    faraday_response = instance_double(Faraday::Response, status: 404, body: {"error" => "not found"})
    allow(Faraday).to receive(:post).and_return(faraday_response)
    expect {
      client.graphql("SomeOp", {})
    }.to raise_error(Whop::NotFoundError)
  end

  it "maps timeout to APITimeoutError" do
    allow(Faraday).to receive(:post).and_raise(Faraday::TimeoutError.new("timeout"))
    expect {
      client.graphql("SomeOp", {})
    }.to raise_error(Whop::APITimeoutError)
  end
end


