require "./config"

module Autopass
  module PasswordGenerator
    LOWER = ('a'..'z').to_a
    UPPER = ('A'..'Z').to_a
    NUMBERS = ('0'..'9').to_a
    VOWELS = ['a','e','i','o','u','y']
    CONSONANTS = LOWER - VOWELS
    SPECIAL = [
      '!','@','#','$','%','^','&','*','(',')','-','_','=','+','"','|',
      '\'',',','.','/','?','<','>','~','`'
    ]

    record Passphrase, string : String, entropy : Float64 do
      def to_s(io : IO)
        io << '[' << entropy.round.to_i << " bits] "
        io << string
      end
    end

    enum PasswordTypes
      Random
      Pronouncable
      WordList
    end

    private delegate config, to: Autopass

    def generate(type : PasswordTypes)
      case type
      when .random? then generate
      when .pronouncable? then generate_pronouncable
      when .word_list? then generate_from_word_list
      else raise "invalid password type"
      end
    end

    def generate
      config = Autopass.config.password_generation
      pool = build_char_pool(config.character_pools)
      pools = Set(Config::PasswordGeneration::CharacterPools).new
      length = 0
      sample_size = { config.min_length, 1 }.max
      entropy = 0.0

      phrase = String.build do |io|
        loop do
          pool.sample(sample_size, Random::Secure).each do |char|
            io << char
            length += 1
            pools << pool_for(char)
          end

          sample_size = 1
          entropy = Math.log(pool_size(pools), 2) * length
          break if length > config.min_length && entropy > config.min_entropy
        end
      end

      Passphrase.new(phrase, entropy)
    end

    def generate_pronouncable
      config = Autopass.config.password_generation
      pools = Set(Config::PasswordGeneration::CharacterPools).new
      length = 0
      last_char = nil
      current_word_length = 0
      entropy = 0.0

      phrase = String.build do |io|
        loop do
          case current_word_length
          when 0
            char = (LOWER + UPPER).sample(1, Random::Secure).first
            last_char = char.downcase
            current_word_length += 1
          when .> Random::Secure.rand(3..5)
            char = {'-', '_', ' '}.sample(Random::Secure)
            current_word_length = 0
            char_before = nil
          else
            char = LOWER.sample(1, Random::Secure).first
            next unless pronouncable?(last_char, char)
            last_char = char
            current_word_length += 1
          end

          io << char
          length += 1
          pools << pool_for(char)

          entropy = Math.log(LOWER.size, 2) * length
          break if length > config.min_length && entropy > config.min_entropy && !(1..2).includes?(current_word_length)
        end
      end

      Passphrase.new(phrase, entropy)
    end

    def generate_from_word_list
      config = Autopass.config.password_generation
      file_path = config.word_list
      raise "No word_list path set in config" if file_path.nil?
      raise "word_list file doesn't exist" unless File.exists?(file_path)

      file_size = File.size(file_path)
      words = [] of String
      entropy = 0.0

      File.open(file_path) do |file|
        word_count = file.each_line.size
        single_entropy = Math.log(word_count, 2)

        loop do
          file.seek(Random::Secure.rand(file_size))
          file.gets
          word = file.gets
          next if word.nil?
          words << word

          entropy = single_entropy * words.size
          break if words.size > config.min_word_count && entropy > config.min_entropy
        end
      end

      Passphrase.new(words.join(' '), entropy)
    end

    private def build_char_pool(pools)
      result = Array(Char).new
      pools.each do |pool|
        case pool
        when .lower? then result += LOWER
        when .upper? then result += UPPER
        when .numbers? then result += NUMBERS
        when .special? then result += SPECIAL
        when .space? then result << ' '
        end
      end

      result
    end

    private def pool_for(char)
      case char
      when 'a'..'z' then Config::PasswordGeneration::CharacterPools::Lower
      when 'A'..'Z' then Config::PasswordGeneration::CharacterPools::Upper
      when '0'..'9' then Config::PasswordGeneration::CharacterPools::Numbers
      else Config::PasswordGeneration::CharacterPools::Special
      end
    end

    private def pool_size(pools)
      pools.sum do |pool|
        case pool
        when Config::PasswordGeneration::CharacterPools::Lower then LOWER.size
        when Config::PasswordGeneration::CharacterPools::Upper then UPPER.size
        when Config::PasswordGeneration::CharacterPools::Numbers then NUMBERS.size
        else SPECIAL.size
        end
      end
    end

    private def pool_size_pronouncable(pools)
      pools.sum do |pool|
        case pool
        when Config::PasswordGeneration::CharacterPools::Lower then LOWER.size
        when Config::PasswordGeneration::CharacterPools::Upper then UPPER.size
        else 3
        end
      end
    end

    private def pronouncable?(char_before, next_char)
      char_before.nil? || VOWELS.includes?(char_before) || VOWELS.includes?(next_char)
    end

    extend self
  end
end
