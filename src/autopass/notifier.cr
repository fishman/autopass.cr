require "notify"
require "./loggable"

module Autopass
  class Notifier
    include Loggable

    private getter notifier : Notify, last_id : UInt32

    def initialize
      @notifier = Notify.new
      @last_id = 0_u32
    end

    def debug(string : String)
      {% if flag?(:debug) %}
        notify("DEBUG: #{string}")
      {% end %}
    end

    def info(string : String)
      notify(string)
    end

    def error(string : String)
      notify("Error: #{string}")
    end

    private def notify(string : String)
      @last_id = notifier.notify(
        string,
        app_name: "Autopass",
        replaces_id: last_id
      )
    end
  end
end
