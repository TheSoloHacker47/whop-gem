require "spec_helper"

RSpec.describe "Whop API DSL resources" do
  let(:client) { instance_double(Whop::Client) }
  let(:api) { Whop.api }

  before do
    allow(Whop).to receive(:client).and_return(client)
  end

  it "invokes payments.create_checkout_session with input" do
    expect(client).to receive(:graphql_query).with("createCheckoutSession", kind_of(String), { input: { planId: "plan_1" } }).and_return({})
    api.payments.create_checkout_session(input: { planId: "plan_1" })
  end

  it "invokes invoices.get_invoice with ids" do
    expect(client).to receive(:graphql_query).with("getInvoice", kind_of(String), { invoiceId: "inv_1", companyId: "biz_1" }).and_return({})
    api.invoices.get_invoice(invoiceId: "inv_1", companyId: "biz_1")
  end

  it "invokes promo_codes.get_promo_code with code and plan" do
    expect(client).to receive(:graphql).with("getPromoCode", { code: "WELCOME10", planId: "plan_1" }).and_return({})
    api.promo_codes.get_promo_code(code: "WELCOME10", planId: "plan_1")
  end

  it "invokes apps.create_app with input" do
    expect(client).to receive(:graphql).with("createApp", { input: { name: "My App" } }).and_return({})
    api.apps.create_app(input: { name: "My App" })
  end

  it "invokes webhooks.list_webhooks with pagination" do
    expect(client).to receive(:graphql).with("listWebhooks", { first: 10 }).and_return({})
    api.webhooks.list_webhooks(first: 10)
  end

  it "invokes messages.send_message_to_chat with variables" do
    expect(client).to receive(:graphql).with("sendMessageToChat", { experienceId: "exp_1", message: "Hello", attachments: nil }).and_return({})
    api.messages.send_message_to_chat(experienceId: "exp_1", message: "Hello", attachments: nil)
  end

  it "invokes notifications.send_push_notification with input" do
    expect(client).to receive(:graphql).with("sendPushNotification", { input: { userId: "user_1", title: "Hi", body: "Welcome" } }).and_return({})
    api.notifications.send_push_notification(input: { userId: "user_1", title: "Hi", body: "Welcome" })
  end

  it "invokes users.get_current_user with no variables" do
    expect(client).to receive(:graphql).with("getCurrentUser", {}).and_return({})
    api.users.get_current_user
  end

  it "invokes experiences.list_experiences with pagination" do
    expect(client).to receive(:graphql).with("listExperiences", { first: 5 }).and_return({})
    api.experiences.list_experiences(first: 5)
  end

  it "invokes companies.get_company with id" do
    expect(client).to receive(:graphql).with("getCompany", { companyId: "biz_1" }).and_return({})
    api.companies.get_company(companyId: "biz_1")
  end
end


