require "./entry"
require "./api"

module Autopass
  class AtomDialog
    def initialize(@entry : Entry)
    end

    abstract def show(&block : String, API::AtomAction ->)
  end
end
