require "rofi"
require "./entry_dialog"
require "./api"

module Autopass
  class RofiEntryDialog < EntryDialog
    class EmptySelection < Exception
      def initialize
        super("empty selection")
      end
    end

    def show
      rofi_dialog = Rofi::Dialog.new(
        entries,
        prompt: "Search",
        message: message,
        matching_method: Rofi::MatchingMethod::Fuzzy,
        key_bindings: key_bindings,
        case_insensitive: true
      )

      dialog_result = rofi_dialog.show
      raise EmptySelection.new if dialog_result.nil?

      action = API::Actions.from_value(dialog_result.key_code)
      entry = dialog_result.selected_entry

      {% begin %}
        case action
        when {{(1..6).map { |i| "API::Actions::Autotype#{i}".id }.splat}}
          sleep(entry.try(&.secret.alt_delay) || config.alt_delay)
        end
      {% end %}

      yield(action, entry)
    end

    private def autotypes
      {% begin %}
        {
          "Enter" => config.autotype,
          {% for i in 1..6 %}
            "Alt-{{ i }}" =>  config.autotype_{{i}},
          {% end %}
        }.each.reject { |(_, autotype)| autotype.empty? }
      {% end %}
    end

    private def messages
      autotype_messages = autotypes.map do |(binding, autotype)|
        "#{binding}: Autotype #{autotype.join(' ')}"
      end

      autotype_messages.to_a + [
        "#{config.key_bindings.select_tan}: Select TAN",
        "#{config.key_bindings.copy_password}: Copy password",
        "#{config.key_bindings.copy_username}: Copy username",
        "#{config.key_bindings.copy_otp}: Copy OTP-Code",
        "#{config.key_bindings.open_browser}: Open URL in browser",
        "#{config.key_bindings.open_entry}: Open Entry"
      ]
    end

    private def message
      String.build do |io|
        half = (messages.size / 2.0).ceil.to_i
        messages.first(half).each_with_index do |message, index|
          io << message.ljust(40, ' ')
          io << messages[half + index]?
            io.puts
        end
      end
    end

    private def key_bindings
      {
        config.key_bindings.select_tan => API::Actions::SelectTan.value,
        config.key_bindings.copy_password => API::Actions::CopyPass.value,
        config.key_bindings.copy_username => API::Actions::CopyUser.value,
        config.key_bindings.copy_otp => API::Actions::CopyOTP.value,
        config.key_bindings.open_browser => API::Actions::OpenBrowser.value,
        config.key_bindings.open_entry => API::Actions::OpenEntry.value
      }
    end
  end
end
