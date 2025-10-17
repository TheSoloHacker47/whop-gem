require "spec_helper"

RSpec.describe Whop::DSL do
  it "defines resources and proxies to client" do
    registry = described_class.registry
    described_class.define do
      resource :things do
        graphql :check, operation: "CheckThings", args: %i[userId]
        rest_get :get, path: "/v5/things/:id", args: %i[id]
      end
    end

    client = instance_double(Whop::Client)
    proxy = Whop::DSL::ClientProxy.new(client, registry)

    expect(client).to receive(:graphql).with("CheckThings", { userId: "u1" }).and_return({})
    proxy.things.check(userId: "u1")

    expect(client).to receive(:get).with("/v5/things/abc", params: {}).and_return({})
    proxy.things.get(id: "abc")
  end
end


