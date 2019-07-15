require "rofi"
require "./entry_sorter"
require "./api"

module Autopass
  abstract class EntryDialog
    def initialize(@store : Store)
    end

    private delegate config, to: Autopass

    abstract def show(&block : Api::Action, Entry? ->)

    protected def entries
      sorter = EntrySorter.new(@store)
      sorter.sorted_entries
    end
  end
end
