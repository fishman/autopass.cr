module Autopass::Converters
  module TanList
    def from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Array(String)
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.class}"
      end

      node.value.split('\n').map(&.strip)
    end

    def to_yaml(value : Array(String), builder : YAML::Nodes::Builder)
      value.join('\n').to_yaml(builder)
    end

    extend self
  end
end
