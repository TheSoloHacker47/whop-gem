require "spec_helper"

RSpec.describe Whop::Access do
  let(:client) { instance_double(Whop::Client) }
  subject(:access) { described_class.new(client) }

  it "extracts hasAccess true from graphql payload" do
    payload = { "data" => { "hasAccessToExperience" => { "hasAccess" => true } } }
    expect(client).to receive(:graphql_query).and_return(payload)
    expect(access.user_has_access_to_experience?(user_id: "u", experience_id: "e")).to be true
  end

  it "returns false when missing" do
    expect(client).to receive(:graphql_query).and_return({ "data" => {} })
    expect(access.user_has_access_to_access_pass?(user_id: "u", access_pass_id: "p")).to be false
  end
end


