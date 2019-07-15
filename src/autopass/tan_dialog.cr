require "./api"

module Autopass
  abstract class TanDialog
    record Tan, index : Int32, number : String do
      def to_s(io : IO)
        index.to_s(io)
      end
    end

    @tans : Array(Tan)

    def initialize(tans : Array(String))
      @tans = tans.map_with_index { |tan, index| Tan.new(index, tan) }
    end

    abstract def show(&block : API::AtomAction, Tan ->)
  end
end
