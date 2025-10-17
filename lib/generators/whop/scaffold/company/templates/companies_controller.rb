class CompaniesController < ApplicationController
  include Whop::ControllerHelpers
  before_action -> { require_whop_access!(company_id: params[:companyId] || params[:id]) }

  def show
    user_id = whop_user_id
    company_id = params[:companyId] || params[:id]
    company = begin
      Whop.client.with_company(company_id).companies.get(company_id)
    rescue StandardError
      { "id" => company_id }
    end
    render :show, locals: { user_id:, company: }
  end
end


