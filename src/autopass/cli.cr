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

module Autopass
  class CLI

    VALID_COMMANDS = %w[
      dialog
    ]

    private getter api, notifier, state_handler, pidfile : String
    private delegate config, to: Autopass

    def initialize(args)
      args_hash = Digest::MD5.hexdigest(args.to_s)
      @pidfile = File.join(ENV.fetch("XDG_RUNTIME_DIR", Dir.tempdir), "autopass-#{args_hash}.pid")
      if File.exists?(@pidfile)
        begin
          Process.kill(Signal::USR1, File.read(@pidfile).to_i)
          exit
        rescue
          File.delete(@pidfile)
        end
      end

      File.write(@pidfile, Process.pid)

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
      @jobs_running = Channel(Nil).new(1)
      @jobs_done = Channel(Nil).new(1)
      @exit_status = 0
    end

    def run
      @jobs_running.send(nil)

      {% begin %}
        case @command
        {% for command in VALID_COMMANDS %}
        when {{command}} then run_{{command.id}}
        {% end %}
        else abort("Invalid command '#{@command}'\n#{@parser}")
        end
      {% end %}

      @jobs_running.receive
      @jobs_done.send(nil)
    rescue exception
      STDERR.puts(exception.message)
      @exit_status = 1
    end

    def wait
      loop do
        until @jobs_done.empty?
          @jobs_done.receive
        end

        sleep config.close_delay
        break if @jobs_done.empty? && @jobs_running.empty?
      end

      File.delete(pidfile)
      @exit_status
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
        @exit_status = 1
      end
    end

    def restore
      @jobs_running.send(nil)
      state_handler.restore
    rescue exception
      notifier.error(exception.message || exception.to_s)
      @exit_status = 1
    ensure
      @jobs_running.receive
      @jobs_done.send(nil)
    end

    def hard_quit
      File.delete(pidfile)
      exit 1
    end

    private def store
      @store ||= Store.load
    end

    private def handle_state_change(state : StateHandler::State)
      case state.type
      when .entries? then run_dialog
      when .entry? then api.open_entry(state.entry)
      when .tan? then api.select_tan(state.entry)
      when .closed? then close
      end
    end

    private def close(code = 0)
      sleep config.close_delay
    end

    private def cancel_close
      @close_channel.receive?
    end
  end
end

cli = Autopass::CLI.new(ARGV)
Signal::USR1.trap { cli.restore }
Signal::INT.trap { cli.hard_quit }
Signal::TERM.trap { cli.hard_quit }

spawn cli.run
exit cli.wait
