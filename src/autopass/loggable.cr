require "logger"

module Autopass
  module Loggable
    abstract def debug(string : String)
    abstract def info(string : String)
    abstract def error(string : String)
  end
end

class Logger
  include Autopass::Loggable
end
