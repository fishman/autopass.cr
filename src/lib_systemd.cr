@[Link("libsystemd")]
lib LibSystemd
  fun listen_fds = sd_listen_fds(unset_environment : Bool) : Int32
  fun is_fifo = sd_is_fifo(fd : Int32, path : UInt8*) : Bool
end
