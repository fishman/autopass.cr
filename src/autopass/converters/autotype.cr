require "../key"

module Autopass::Converters
  module Autotype
    def from_string(value)
      case value
      when .starts_with?(':') then parse_key(value[1..-1])
      else value
      end
    end

    def to_string(value : String)
      value
    end

    def to_string(value : Key)
      String.build do |io|
        io << ':'
        value.to_s(io)
      end
    end

    def parse_key(key)
      key = "return" if key.downcase == "enter"
      Key.parse(key)
    end

    def from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Array(String | Key)
      if node.is_a?(YAML::Nodes::Sequence)
        node.map do |value|
          from_string(String.new(ctx, value))
        end
      elsif node.is_a?(YAML::Nodes::Scalar)
        node.value.split(/\s+/).map { |value| from_string(value) }
      else
        node.raise "Expected scalar, not #{node.class}"
      end
    end

    def from_any(values : YAML::Any)
      (values.as_a?.try(&.map &.as_s) || values.as_s.split(/\s+/)).map do |value|
        from_string(value)
      end
    end

    def to_yaml(values : Array(String | Key), builder : YAML::Nodes::Builder)
      values.map { |value| to_string(value) }.to_yaml(builder)
    end

    extend self
  end
end
