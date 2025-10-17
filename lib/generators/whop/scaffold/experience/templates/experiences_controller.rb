class ExperiencesController < ApplicationController
  include Whop::ControllerHelpers
  before_action -> { require_whop_access!(experience_id: params[:experienceId] || params[:id]) }

  def show
    user_id = whop_user_id
    exp_id = params[:experienceId] || params[:id]
    experience = begin
      Whop.client.experiences.get(exp_id)
    rescue StandardError
      { "id" => exp_id }
    end
    render :show, locals: { user_id:, experience: }
  end
end


