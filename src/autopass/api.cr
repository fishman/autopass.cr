require "xclib"
require "./xdo"
require "./entry"
require "./loggable"
require "./state_handler"
require "logger"

module Autopass
  class API(T, A)
    enum Actions
      Autotype
      Autotype1
      Autotype2
      Autotype3
      Autotype4
      Autotype5
      Autotype6
      SelectTan
      CopyPass
      CopyUser
      CopyOTP
      OpenBrowser
      OpenEntry
    end

    enum AtomActions
      Autotype
      Copy
      Back
    end

    private delegate xdo, to: Autopass
    private getter log : Loggable, state_handler : StateHandler

    def initialize(@state_handler, @log = Logger.new(STDOUT))
    end

    def autotype(entry : Entry, autotype : Array(String | Key), delay)
      window = target_window_for(entry)
      window.activate!

      autotype.each do |part|
        case part
        when String then window.enter_text(entry.secret[part])
        when Key
          case part
          when Key::Delay then sleep(entry.secret.delay)
          else window.send_keysequence(part.to_s)
          end
        end
      end
    end

    def select_tan(entry)
      raise "no entry selected" if entry.nil?

      secret = entry.secret
      tans = secret.tan
      raise "No tans found for entry" if tans.nil?
      tan_dialog = T.new(tans)
      tan_dialog.show do |action, tan|
        @state_handler.action_performed(action, entry)
        return if action.back?

        raise "No valid tan selected" if tan.nil?
        perform_atom_action(entry, action, tan.number)
      end
    end

    {% for field in %i[pass user otp] %}
      def copy_{{field.id}}(entry)
        secret = entry.secret

        copy(
          secret[{{field.id.stringify}}],
          secret.clipboard_selection,
          secret.clipboard_clear_delay
        )
      end
    {% end %}

    def open_browser(entry)
    end

    def open_entry(entry)
      raise "no entry selected" if entry.nil?

      atom_dialog = A.new(entry)
      atom_dialog.show do |action, key|
        if key == "tan"
          state_handler.action_performed(Actions::SelectTan, entry)
          return select_tan(entry)
        end

        @state_handler.action_performed(action, entry)
        return if action.back?

        perform_atom_action(entry, action, entry.secret[key]?)
      end
    end

    def perform_action(action : Actions, entry : Entry?)
      return state_handler.close if entry.nil?

      state_handler.action_performed(action, entry)

      {% begin %}
        case action
        when .autotype?
          autotype(entry, entry.secret.autotype, entry.secret.type_delay)
        {% for i in 1..6 %}
        when .autotype{{i}}?
          delay = { entry.secret.type_delay, entry.secret.alt_delay }.max
          autotype(entry, entry.secret.autotype_{{i}}, delay)
        {% end %}
        {% for action in %i[select_tan copy_pass copy_user copy_otp open_browser open_entry] %}
        when .{{action.id}}? then {{action.id}}(entry)
        {% end %}
        end
      {% end %}
    end

    private def target_window_for(entry)
      matching_windows = xdo.search_windows(
        name: entry.matcher.source, only_visible: true
      )

      case matching_windows.size
      when 1 then return matching_windows.first
      when .> 1 then log.info("More than one matching window")
      else log.info("No matching window")
      end

      select_target_window
    end

    private def select_target_window
      log.info("Select target window")
      xdo.select_window_with_click
    end

    private def copy(text, selection, clear_delay)
      previous_content = Xclib.load(selection)
      begin
        Xclib.store(text, selection)
        (1..clear_delay.to_i).reverse_each do |i|
          log.info("Clearing clipboard in #{i} seconds")
          sleep 1
        end

        sleep(clear_delay - clear_delay.to_i)
      ensure
        Xclib.store(previous_content, selection)
      end
    end

    private def perform_atom_action(entry, action, value)
      raise "Empty value" if value.nil?

      case action
      when .autotype?
        window = target_window_for(entry)
        window.activate!
        window.enter_text(value)
      when .copy?
        secret = entry.secret
        copy(value, secret.clipboard_selection, secret.clipboard_clear_delay)
      end
    end
  end
end
