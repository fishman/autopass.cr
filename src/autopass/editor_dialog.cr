require "rofi"
require "./api"

module Autopass
  abstract class EditorDialog
    def initialize(@entry : Entry)
    end

    abstract def show(&block : Api::EditActions, String ->)
  end
end
