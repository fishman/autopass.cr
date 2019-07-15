require "./xdo"
require "./entry"

module Autopass
  class EntrySorter
    private delegate xdo, to: Autopass

    def initialize(store)
      active_window = xdo.active_window
      visible_windows = xdo.search_windows(name: ".+", only_visible: true)
      @scores = Hash(Entry, Int32).new

      store.entries.each do |entry|
        @scores[entry] = calculate_score(entry, active_window, visible_windows)
      end
    end

    def sorted_entries
      @scores.keys.sort do |a, b|
        score_comparison = @scores[b] <=> @scores[a]
        score_comparison == 0 ? a.name <=> b.name : score_comparison
      end
    end

    private def calculate_score(entry, active_window, visible_windows)
      score = 0

      if match = entry.matcher.match(active_window.name)
        score += match.size * 100
      else
        score += visible_windows.max_of do |window|
          entry.matcher.match(window.name).try(&.size) || -1
        end
      end

      score
    end
  end
end
