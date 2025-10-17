require "rails/generators"

module Whop
  module Scaffold
    module Generators
      class AllGenerator < Rails::Generators::Base
        argument :company_id, type: :string, required: false, default: nil, desc: "(optional) Whop Company ID"
        argument :experience_id, type: :string, required: false, default: nil, desc: "(optional) Whop Experience ID"

        def scaffold_company
          invoke "whop:scaffold:company", [company_id].compact
        end

        def scaffold_experience
          invoke "whop:scaffold:experience", [experience_id].compact
        end
      end
    end
  end
end


