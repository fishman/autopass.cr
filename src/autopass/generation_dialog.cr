require "./password_generator"
require "./api"

module Autopass
  abstract class GenerationDialog

    def initialize(@password_type : PasswordGenerator::PasswordTypes)
    end

    delegate config, to: Autopass

    abstract def show(&block : Api::Action, Passphrase? ->)

    protected def generate_list
      Array(PasswordGenerator::Passphrase).new(config.password_generation.suggestion_count) do
        PasswordGenerator.generate(@password_type)
      end
    end
  end
end
