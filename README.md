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

## Contributing

1. Fork it (<https://github.com/repomaa/autopass/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [repomaa](https://github.com/repomaa) Joakim Repomaa - creator, maintainer
