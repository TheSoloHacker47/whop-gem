require "spec_helper"

RSpec.describe "GraphQL auto pagination" do
  let(:config) { OpenStruct.new(api_base_url: "https://api.whop.com", api_key: "sk_", agent_user_id: nil, company_id: nil) }
  subject(:client) { Whop::Client.new(config) }

  it "iterates pages using pageInfo and endCursor" do
    page1 = { "data" => { "company" => { "receipts" => { "nodes" => [ {"id" => "r1"} ], "pageInfo" => { "hasNextPage" => true, "endCursor" => "c1" } } } } }
    page2 = { "data" => { "company" => { "receipts" => { "nodes" => [ {"id" => "r2"} ], "pageInfo" => { "hasNextPage" => false, "endCursor" => nil } } } } }

    calls = []
    allow(client).to receive(:graphql) do |op, vars|
      calls << vars
      calls.length == 1 ? page1 : page2
    end

    results = []
    client.graphql_each_page("listReceiptsForCompany", { companyId: "biz_1" }, path: ["company", "receipts"], first: 1) do |node|
      results << node["id"]
    end

    expect(results).to eq(["r1", "r2"])
    expect(calls[0]).to include(first: 1)
    expect(calls[1]).to include(after: "c1")
  end
end


