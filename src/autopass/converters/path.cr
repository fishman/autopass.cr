module Autopass::Converters
  module Path
    def from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : String
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.class}"
      end

      File.expand_path(node.value % ENV.to_h)
    end

    def to_yaml(value : String, builder : YAML::Nodes::Builder)
      value.to_yaml(builder)
    end

    extend self
  end
end
