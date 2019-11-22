module Autopass::Converters
  module TimeSpan
    MATCHER = /^(?<value>\d+(?:\.\d+)?)(?:\.(?<unit>second|minute|hour|day)s?)?$/

    def from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Time::Span
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.class}"
      end

      match = node.value.match(MATCHER)
      node.raise "Invalid time span '#{node.value}'" if match.nil?

      case match["unit"]?
      when "second" then match["value"].to_f.seconds
      when "hour" then match["value"].to_f.hours
      when "day" then match["value"].to_f.days
      else match["value"].to_f.minutes
      end
    end

    def to_yaml(value, builder)
      builder.scalar(value.total_minutes)
    end

    extend self
  end
end
