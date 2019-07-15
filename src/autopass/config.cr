require "xclib"
require "yaml"
require "./key"
require "./converters/path"
require "./converters/autotype"
require "./gpg"
require "./entry"

module Autopass
  def self.config
    @@config ||= load_config!
  end

  def self.load_config!(path = File.join(ENV.fetch("XDG_CONFIG_HOME", "~/.config"), "autopass", "config.yml"))
    path = File.expand_path(path)

    @@config = File.exists?(path) ? Config.load(path) : Config.new
  end

  class Config
    include YAML::Serializable
    include YAML::Serializable::Strict

    @[YAML::Field(converter: Autopass::Converters::Path)]
    getter password_store : String = File.expand_path(
      ENV.fetch("PASSWORD_STORE_DIR", "~/.password_store")
    )

    getter? use_cache : Bool = true
    @cache_key : String?
    @[YAML::Field(converter: Autopass::Converters::Path)]
    getter cache_file : String = File.expand_path(
      File.join(ENV.fetch("XDG_CACHE_HOME", "~/.cache"), "autopass", "cache.gpg")
    )
    getter alt_delay : Float64 | Int32 = 1
    getter delay : Float64 | Int32 = 0.5
    getter close_delay : Float64 | Int32 = 10
    getter clipboard_selection : Xclib::Selection = Xclib::Selection::Primary
    getter clipboard_clear_delay : Float64 | Int32 = 10

    getter username_key : String = "user"
    getter password_key : String = "pass"

    @[YAML::Field(converter: Autopass::Converters::Autotype)]
    getter autotype : Array(String | Key) = ["user", Autopass::Key::Tab, "pass"]
    @[YAML::Field(converter: Autopass::Converters::Autotype)]
    getter autotype_1 : Array(String | Key) = ["pass"] of String | Autopass::Key
    @[YAML::Field(converter: Autopass::Converters::Autotype)]
    getter autotype_2 : Array(String | Key) = ["user"] of String | Autopass::Key
    @[YAML::Field(converter: Autopass::Converters::Autotype)]
    getter autotype_3 : Array(String | Key) = ["otp"] of String | Autopass::Key
    @[YAML::Field(converter: Autopass::Converters::Autotype)]
    getter autotype_4 : Array(String | Key) = [] of String | Autopass::Key
    @[YAML::Field(converter: Autopass::Converters::Autotype)]
    getter autotype_5 : Array(String | Key) = [] of String | Autopass::Key
    @[YAML::Field(converter: Autopass::Converters::Autotype)]
    getter autotype_6 : Array(String | Key) = [] of String | Autopass::Key

    getter browsers : Array(String) = %w[firefox chromium chrome]
    getter key_bindings : Autopass::Config::KeyBindings = Autopass::Config::KeyBindings.new

    def initialize
    end

    def cache_key
      @cache_key ||= Autopass.gpg.list_keys(secret_only: true).first.id
    end

    def self.load(path)
      File.open(path) do |file|
        from_yaml(file)
      end
    end

    class KeyBindings
      include YAML::Serializable
      include YAML::Serializable::Strict

      getter select_tan : String = "Alt-t"
      getter copy_password : String = "Alt-p"
      getter copy_username : String = "Alt-u"
      getter copy_otp : String = "Alt-c"
      getter open_browser : String = "Alt-o"
      getter open_entry : String = "Alt-e"

      def initialize
      end
    end
  end
end
