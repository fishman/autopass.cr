require "option_parser"
require "./config"
Autopass.load_config!

require "digest/md5"
require "./notifier"
require "./store"
require "./rofi_entry_dialog"
require "./rofi_tan_dialog"
require "./rofi_atom_dialog"
require "./state_handler"

{% unless flag?(:no_systemd) %}
  require "./systemd_socket_activation"
{% end %}

module Autopass
  class CLI

    VALID_COMMANDS = %w[
      dialog
    ]

    private getter api, notifier, state_handler
    private delegate config, to: Autopass

    def initialize(args)
      @parser = OptionParser.new do |p|
        p.on("-h", "--help", "Show this message") do
          puts p
          exit
        end
      end

      @parser.parse(args)
      @command = args.first? || "dialog"

      @notifier = Notifier.new
      @state_handler = StateHandler.new do |state|
        handle_state_change(state)
      end

      @api = API(RofiTanDialog, RofiAtomDialog).new(state_handler, notifier)
    end

    def run
      {% begin %}
        case @command
        {% for command in VALID_COMMANDS %}
        when {{command}} then run_{{command.id}}
        {% end %}
        else abort("Invalid command '#{@command}'\n#{@parser}")
        end
      {% end %}
    rescue exception
      abort(exception.message)
    end

    def listen(fifo : IO::Evented)
      fifo.read_timeout = Autopass.config.server_timeout

      loop do
        fifo.gets
        puts "Got signal"
        begin
          @state_handler.restore
        rescue error : RofiEntryDialog::EmptySelection
          fifo.puts(error.message)
        end
      end
    rescue IO::Timeout
      puts "Timeout"
      exit
    rescue error
      STDERR.puts(error.message)
      fifo.puts(error.message)
      exit 1
    end

    def run_dialog
      dialog = RofiEntryDialog.new(store)

      begin
        dialog.show do |action, entry|
          notifier.debug("Action: #{action}, Entry: #{entry}")
          api.perform_action(action, entry)
        end
      rescue exception
        notifier.error(exception.message || exception.to_s)
        raise exception
      end
    end

    private def store
      @store ||= Store.load
    end

    private def handle_state_change(state : StateHandler::State)
      case state.type
      when .entries? then run_dialog
      when .entry? then api.open_entry(state.entry)
      when .tan? then api.select_tan(state.entry)
      end
    end
  end
end

cli = Autopass::CLI.new(ARGV)

{% begin %}
  {% unless flag?(:no_systemd) %}
    if Autopass::SystemdSocketActivation.was_socket_activated?
      cli.listen(Autopass::SystemdSocketActivation.fifo)
    else
  {% end %}
    cli.run
  {% unless flag?(:no_systemd) %}
    end
  {% end %}
{% end %}
