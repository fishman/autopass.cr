DEFAULT_FLAGS := --release
BUILD_FLAGS :=
PREFIX := /usr

bin/autopass:
	shards build $(DEFAULT_FLAGS) $(BUILD_FLAGS)

install: bin/autopass
	install bin/autopass -m755 -D $(PREFIX)/bin/autopass

.PHONY: bin/autopass install systemd
