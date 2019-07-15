module Autopass::Converters
  module Regex
    def from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : ::Regex
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.class}"
      end

      ::Regex.new(node.value, ::Regex::Options::IGNORE_CASE)
    end

    def to_yaml(value : ::Regex, builder : YAML::Nodes::Builder)
      value.source.to_yaml(builder)
    end

    extend self
  end
end
