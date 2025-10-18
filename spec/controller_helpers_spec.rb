require "spec_helper"
require "ostruct"

class DummyController
  include Whop::ControllerHelpers

  attr_reader :request

  def initialize(headers: {}, params: {})
    @request = Struct.new(:headers, :get_header).new(headers, ->(k) { headers[k] })
    @params = params
  end

  def params
    @params
  end

  def render(*); end
end

RSpec.describe Whop::ControllerHelpers do
  it "current_whop_user_id proxies whop_user_id" do
    controller = DummyController.new
    expect(controller).to receive(:whop_user_id).and_return("u1")
    expect(controller.send(:current_whop_user_id)).to eq("u1")
  end

  it "require_whop_user! raises when missing" do
    controller = DummyController.new
    expect { controller.send(:require_whop_user!) }.to raise_error(Whop::Error)
  end

  it "current_whop_user fetches via REST when token present" do
    token = "header.jwt"
    headers = { "x-whop-user-token" => token }
    controller = DummyController.new(headers: headers)
    allow(Whop::Token).to receive(:verify_from_jwt).with(token).and_return({ "sub" => "user_1", "aud" => nil })
    allow(ENV).to receive(:[]).with("WHOP_APP_ID").and_return(nil)
    allow(Whop).to receive(:config).and_return(OpenStruct.new(app_id: nil))
    expect(Whop.client).to receive_message_chain(:users, :get).with("user_1").and_return({ "id" => "user_1" })
    expect(controller.send(:current_whop_user)).to eq({ "id" => "user_1" })
  end
end


