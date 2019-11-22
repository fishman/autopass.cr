DEFAULT_FLAGS := --release --production
BUILD_FLAGS :=
PREFIX := /usr

bin/autopass:
	shards build $(DEFAULT_FLAGS) $(BUILD_FLAGS)

install: bin/autopass
	install bin/autopass -m755 -D $(PREFIX)/bin/autopass

release: bin/release
	bin/release

bin/release: scripts/release.cr
	crystal build $^ -o $@

.PHONY: bin/autopass install systemd release
