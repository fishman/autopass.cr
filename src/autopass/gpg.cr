require "gpg"

module Autopass
  def self.gpg
    @@gpg ||= GPG.new
  end
end
