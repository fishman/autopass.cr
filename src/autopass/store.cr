require "yaml"
require "./entry"

module Autopass
  class Store
    DOTS = [".  ", ".. ", "..."].cycle

    include YAML::Serializable

    getter entries : Set(Entry)

    def self.load
      cache_file = Autopass.config.cache_file

      if File.exists?(cache_file) && Autopass.config.use_cache?
        File.open(cache_file) do |cache|
          cleartext = Autopass.gpg.decrypt(cache.gets_to_end)
          from_yaml(cleartext)
        end
      else
        new
      end
    end

    def initialize
      @entries = Set(Entry).new
      refresh
    end

    def self.from_yaml(yaml)
      super.tap(&.refresh)
    end

    def refresh
      Dir[File.join(Autopass.config.password_store, "**/*.gpg")].map do |path|
        @entries << Entry.new(path)
      end

      return unless Autopass.config.use_cache?

      marked_for_deletion = [] of Entry

      @entries.each_with_index do |entry, index|
        print "> Refreshing cache#{DOTS.next} #{progress(index)}%\r"
        marked_for_deletion << entry if entry.deleted?
        entry.decrypt if entry.changed? || !entry.decrypted?
      end

      puts

      marked_for_deletion.each do |entry|
        @entries.delete(entry)
      end

      spawn save!
    end

    def save!
      Dir.mkdir_p(File.dirname(Autopass.config.cache_file))

      File.open(Autopass.config.cache_file, "w+") do |cache|
        recipient = Autopass.gpg.list_keys(Autopass.config.cache_key).first?
        ciphertext = Autopass.gpg.encrypt(to_yaml, recipient)
        cache << ciphertext
      end
    end

    def progress(index)
      (index + 1) * 100 / @entries.size
    end
  end
end
