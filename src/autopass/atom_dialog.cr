require "rofi"
require "./api"

module Autopass
  abstract class AtomDialog
    def initialize(@entry : Entry)
    end

    abstract def show(&block : Api::AtomActions, String ->)
  end
end
