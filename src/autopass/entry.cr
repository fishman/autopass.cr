require "./converters/autotype"
require "./converters/regex"
require "./converters/tan_list"
require "./key"
require "./config"
require "./gpg"
require "openssl"
require "crotp"

require "yaml"

module Autopass
  class Entry
    include YAML::Serializable

    private delegate config, to: Autopass

    getter path : String
    getter name : String
    @[YAML::Field(converter: Autopass::Converters::Regex)]
    getter matcher : Regex

    @secret : Secret?
    @checksum : String?

    def initialize(path)
      @path = File.expand_path(path)
      @name = @path[(config.password_store.size + 1)..-5]
      @matcher = Regex.new(
        Regex.escape(File.basename(@name)),
        Regex::Options::IGNORE_CASE
      )
    end

    def to_s(io : IO)
      @name.to_s(io)
    end

    def secret
      @secret ||= decrypt
    end

    def decrypted?
      !@secret.nil?
    end

    def deleted?
      !File.exists?(@path)
    end

    def changed?
      File.open(@path) do |file|
        io = OpenSSL::DigestIO.new(file, "sha3-224")
        io.gets_to_end
        @checksum != io.hexdigest
      end
    end

    def ==(other : Entry)
      path == other.path
    end

    def hash
      path.hash
    end

    def decrypt
      File.open(@path) do |file|
        io = OpenSSL::DigestIO.new(file, "sha3-224")
        ciphertext = io.gets_to_end
        cleartext = Autopass.gpg.decrypt(ciphertext)
        lines = cleartext.lines
        pass = lines.shift
        lines.shift if lines.first? == "---"

        yaml = String.build do |io|
          { config.password_key => pass }.to_yaml(io)
          lines.each { |line| io.puts(line) }
        end

        @checksum = io.hexdigest
        @secret = Secret.from_yaml(yaml).tap do |secret|
          secret.window.try { |window| @matcher = window }
        end
      end
    rescue ex : Exception
      raise "Failed to decrypt #{@path}: #{ex.message}"
    end

    class Secret
      include YAML::Serializable
      include YAML::Serializable::Unmapped

      CONFIG_KEYS = %i[
        alt_delay
        delay
        clipboard_selection
        clipboard_clear_delay
        type_delay
        autotype
        autotype_1
        autotype_2
        autotype_3
        autotype_4
        autotype_5
        autotype_6
        username_key
        password_key
      ]

      @[YAML::Field(converter: Autopass::Converters::Regex)]
      getter window : Regex?
      getter otp_secret : String?
      @[YAML::Field(converter: Autopass::Converters::TanList)]
      getter tan : Array(String)?
      getter url : String?

      @alt_delay : Float64?
      @delay : Float64?
      @type_delay : Float64?
      @clipboard_selection : Xclib::Selection?
      @clipboard_clear_delay : Int32?

      @username_key : String?
      @password_key : String?

      {% for key in CONFIG_KEYS.select { |key| key.starts_with?("autotype") } %}
        @[YAML::Field(converter: Autopass::Converters::Autotype)]
        @{{key.id}} : Array(String | Key)?
      {% end %}

      def pass
        unmapped(password_key)
      end

      def user
        unmapped(username_key)
      end

      def []?(key)
        case key.to_s
        when "pass" then pass
        when "user" then user
        when "otp" then otp
        else unmapped(key.to_s)
        end
      end

      def keys
        ([] of String).tap do |keys|
          @yaml_unmapped.keys.each do |key|
            keys << key
          end

          keys << "tan" if tan
          keys << "url" if url
          keys << "otp_secret" if otp_secret
        end
      end

      def otp
        secret = otp_secret
        raise "Missing otp secret" if secret.nil?
        otp = CrOTP::TOTP.new(secret)
        otp.generate
      end

      def [](key)
        value = self[key]?
        raise KeyError.new("Missing key: #{key}") if value.nil?
        value
      end

      def unmapped
        @yaml_unmapped
      end

      {% for key in CONFIG_KEYS %}
        def {{key.id}}
          @{{key.id}} || Autopass.config.{{key.id}}
        end
      {% end %}


      private def unmapped(key)
        @yaml_unmapped[key]?.try(&.to_s)
      end
    end
  end
end
