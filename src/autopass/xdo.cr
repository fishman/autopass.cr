require "xdo"

module Autopass
  def self.xdo
    @@xdo ||= Xdo.new
  end
end
