require "rails/generators"

module Whop
  module Webhooks
    module Generators
      class HandlerGenerator < Rails::Generators::NamedBase
        source_root File.expand_path("templates", __dir__)

        def create_job
          template "job.rb", File.join("app/jobs/whop", "#{file_name}_job.rb")
        end
      end
    end
  end
end


