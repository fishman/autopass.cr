require "rofi"
require "./generation_dialog"
require "./api"

module Autopass
  class RofiGenerationDialog < GenerationDialog
    def show
      rofi_dialog = Rofi::Dialog.new(
        generate_list,
        prompt: "Select a password",
        message: message,
        matching_method: Rofi::MatchingMethod::Fuzzy,
        key_bindings: key_bindings,
        case_insensitive: true
      )

      dialog_result = rofi_dialog.show
      raise "empty selection" if dialog_result.nil?

      action = API::GenerateActions.from_value(dialog_result.key_code)
      entry = dialog_result.selected_entry

      yield(action, entry)
    end

    private def message
      password_types = PasswordGenerator::PasswordTypes.values.cycle
      until password_types.next == @password_type
      end

      String.build do |io|
        io.puts("Enter: Select")
        io.puts("Alt+m: Switch to #{password_types.next} type")
        io.puts("Alt+q: Back")
      end
    end

    private def key_bindings
      {
        "Alt+r" => API::GenerateActions::Refresh.value,
        "Alt+m" => API::GenerateActions::TypeSwitch.value,
        "Alt+q" => API::GenerateActions::Back.value,
      }
    end
  end
end
