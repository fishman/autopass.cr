require "rofi"
require "./tan_dialog"
require "./api"

module Autopass
  class RofiTanDialog < TanDialog
    def show
      rofi_dialog = Rofi::Dialog.new(
        @tans,
        prompt: "Enter TAN",
        matching_method: Rofi::MatchingMethod::Normal,
        message: message,
        key_bindings: key_bindings,
      )

      dialog_result = rofi_dialog.show
      if dialog_result.nil?
        yield(API::AtomActions::Back, nil)
      else
        action = API::AtomActions.from_value(dialog_result.key_code)
        yield(action, dialog_result.selected_entry)
      end
    end

    private def message
      String.build do |io|
        io.puts("Enter: Autotype")
        io.puts("Alt+c: Copy")
        io.puts("Alt+q: Back")
      end
    end

    private def key_bindings
      {
        "Alt+c" => API::AtomActions::Copy.value,
        "Alt+q" => API::AtomActions::Back.value,
      }
    end
  end
end
