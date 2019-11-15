require "rofi"
require "./editor_dialog"

module Autopass
  class RofiEditorDialog < EditorDialog
    private delegate config, to: Autopass

    def show
      existing_keys = @entry.secret.keys
      possible_keys = @entry.secret.possible_keys.sort
      active_rows = existing_keys.map { |key| possible_keys.index(key) }

      rofi_dialog = Rofi::Dialog.new(
        possible_keys,
        prompt: "Choose an existing or new field",
        active_rows: active_rows.compact,
        message: message,
        matching_method: Rofi::MatchingMethod::Fuzzy,
        key_bindings: key_bindings,
        case_insensitive: true
      )

      dialog_result = rofi_dialog.show
      if dialog_result.nil?
        yield(API::EditActions::Back, nil)
      else
        action = API::EditActions.from_value(dialog_result.key_code)
        yield(action, dialog_result.selected_entry || dialog_result.input)
      end
    end

    private def message
      String.build do |io|
        io.puts("Enter: Edit selected field")
        io.puts("Alt+g: Generate a random string for the selected field")
        io.puts("Alt+s: Save the entry")
        io.puts("Alt+q: Back")
      end
    end

    private def key_bindings
      {
        "Alt+g" => API::EditActions::GenerateField.value,
        "Alt+s" => API::EditActions::Save.value,
        "Alt+q" => API::EditActions::Back.value,
      }
    end
  end
end
