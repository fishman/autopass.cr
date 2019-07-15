require "./api"
require "./entry"

module Autopass
  class StateHandler
    enum Types
      Entries
      Entry
      Tan
      Closed
    end

    record State, type : Types, entry : Entry? = nil

    private getter states : Array(State) = default_state

    def initialize(&block : State ->)
      @change_handler = block
    end

    def action_performed(action : API::Actions | API::AtomActions, entry : Entry)
      case action
      when API::Actions
        case action
        when .select_tan? then states << State.new(Types::Tan, entry)
        when .open_entry? then states << State.new(Types::Entry, entry)
        end
      else
        if action.back?
          states.pop
          restore
        end
      end
    end

    def close
      @change_handler.call(State.new(Types::Closed))
    end

    def restore
      @change_handler.call(states.last)
    end

    def self.default_state
      [State.new(Types::Entries)]
    end
  end
end
