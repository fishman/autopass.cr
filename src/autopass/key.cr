module Autopass
  enum Key
    Tab
    Return
    Space
    Delay

    def to_s(io : IO)
      case self
      when Tab then io << "Tab"
      when Return then io << "Return"
      when Space then io << "space"
      when Delay then io << "delay"
      end
    end

    def to_s
      String.build { |io| to_s(io) }
    end
  end
end
