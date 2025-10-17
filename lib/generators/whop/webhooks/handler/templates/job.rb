class <%= class_name %>Job < ApplicationJob
  queue_as :default

  def perform(event)
    # event is a Hash with keys: "action", "data", etc.
    Rails.logger.info("Whop webhook <%= file_name %> received: #{event.inspect}")
  end
end


