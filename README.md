# autopass.cr

This is a complete rewrite of [repomaa/autopass](/repomaa/autopass) with a focus
on maintainability, stability and safety. It's mostly backwards compatible
although you should remove your cache (`$XDG_CACHE_DIR/autopass/cache.gpg`) and
let autopass.cr rebuild it.

autopass.cr doesn't shell out for gpg, xclip or autotyping over xdotool but
instead uses native libraries.

## Installation

### ArchLinux

Be sure to import my GPG key:

[`CC7B D43A 315E BC37 3F9A 1F2E EFEB 16CB 1C89 52C5`](https://keys.openpgp.org/vks/v1/by-fingerprint/CC7BD43A315EBC373F9A1F2EEFEB16CB1C8952C5)

Get one of the following AUR packages:

- https://aur.archlinux.org/autopass.cr-bin
- https://aur.archlinux.org/autopass.cr
- https://aur.archlinux.org/autopass.cr-git

### Other systems

Install the following make dependencies:

- crystal
- shards
- rust
- cargo
- git
- python

Install the following runtime dependencies:

- gpgme
- rofi
- xdotool
- gc
- libyaml
- libevent

run `make install`

## Usage

Start autopass.cr by running `autopass`. It will take a while to fill the
cache if you have a lot of entries. For config options see the
[autopass docs](/repomaa/autopass/tree/master/README).

### Socket activation

autopass.cr supports systemd socket activation. This allows the program to keep
running in the background with the decrypted cache and last state (e.g. last
open entry) in ram so starting up and restoring the state is much faster.

You can find examples for socket and service units in
[autopass.socket](/repomaa/autopass.cr/tree/master/autopass.socket) and
[autopass.service](/repomaa/autopass.cr/tree/master/autopass.service).

If you installed autopass.cr from AUR, socket and service files have been set up
for you. Start the socket by running `systemctl --user start autopass.socket`.
This will open a FIFO `$XDG_RUNTIME_DIR/autopass.fifo`. To start autopass simply
write anything followed by newline on the FIFO: `echo start >>
$XDG_RUNTIME_DIR/autopass.fifo`.

autopass will keep running in the background for 15 minutes by default. You can
adjust this value with the option `server_timeout`. Here are some examples for
possible values for the setting:

- `1.hour`
- `30.seconds`
- `5.days`
- `20` (values without units are treated as minutes)

## Contributing

1. Fork it (<https://github.com/repomaa/autopass/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [repomaa](https://github.com/repomaa) Joakim Repomaa - creator, maintainer
