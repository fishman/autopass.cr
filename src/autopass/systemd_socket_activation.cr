require "socket"
require "../lib_systemd"

module Autopass
  module SystemdSocketActivation
    def was_socket_activated?
      LibSystemd.listen_fds(false) > 0
    end

    def fifo
      if LibSystemd.is_fifo(3, nil)
        IO::FileDescriptor.new(3)
      else
        raise "Only FIFO socket activation is supported"
      end
    end

    extend self
  end
end
