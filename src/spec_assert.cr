require "spec"

module Spec
  module DSL
    private def expected(a, s, b)
      String.build do |io|
        delta = s.size - "expected".size
        if delta >= 0
          io << " " * delta << "expected  " << a << "\n" << s << "  " << b
        else
          io << "expected  " << a << "\n" << " " * -delta << s << "  " << b
        end
      end
    end

    # Check that the expression is true, or raise AssertionError otherwise
    macro assert(exp, file = __FILE__, line = __LINE__, bool = true)
      {% if exp.is_a?(Not) %}
        assert({{exp.exp}}, {{file}}, {{line}}, {{!bool}})
      {% else %}
        {% call = exp.is_a?(Call) && (obj = exp.receiver) && !exp.args.empty? && (arg = exp.args[0]) %}
        {% if call && %w[== != < > <= >=].includes? exp.name.stringify %}
          %a, %b = {{obj}}, {{arg}}
          if {% if bool %}!{% end %}(%a {{exp.name}} %b)
            %ai, %bi = %a.inspect, %b.inspect
            if %ai == %bi
              %ai += " : #{%a.class}"
              %bi += " : #{%b.class}"
            end
            raise Spec::AssertionFailed.new(expected(
              %ai,
              "{% if !bool %}not {% end %}to {% unless exp.name == "==" || exp.name == "!=" %}be {% end %}{{exp.name}}", %bi
            ), {{file}}, {{line}})
          end
        {% elsif call && (exp.name == "=~" || exp.name == "!~") %}
          %a, %b = {{obj}}, {{arg}}
          if {% if bool %}!{% end %}(%a {{exp.name}} %b)
            raise Spec::AssertionFailed.new(expected(
              %a.inspect,
              "{% if bool != (exp.name == "=~") %}not {% end %}to match", %b.inspect
            ), {{file}}, {{line}})
          end
        {% elsif exp.is_a?(IsA) %}
          %a = {{exp.receiver}}
          if {% if bool %}!{% end %}(%a.is_a?({{exp.arg}}))
            raise Spec::AssertionFailed.new(expected(
              %a.inspect,
              "{% if !bool %}not {% end %}to be a", {{exp.arg}}.inspect
            ), {{file}}, {{line}})
          end
        {% elsif call && exp.name == "same?" %}
          %a, %b = {{obj}}, {{arg}}
          if {% if bool %}!{% end %}(%a.same?(%b))
            raise Spec::AssertionFailed.new(expected(
              "#{%a.inspect}  @ 0x#{%a.object_id.to_s(16)}",
              "{% if !bool %}not {% end %}to be", "#{%a.inspect}  @ 0x#{%b.object_id.to_s(16)}"
            ), {{file}}, {{line}})
          end
        {% elsif call && exp.name == "includes?" %}
          %a, %b = {{obj}}, {{arg}}
          if {% if bool %}!{% end %}(%a.includes?(%b))
            raise Spec::AssertionFailed.new(expected(
              %a.inspect,
              "{% if !bool %}not {% end %}to include", %b.inspect
            ), {{file}}, {{line}})
          end
        {% else %}
          %a = {{exp}}
          if {% if bool %}!{% end %}(
            {% if exp.is_a? Var %} {{exp}} {% else %} %a {% end %}
          )
            raise Spec::AssertionFailed.new(expected(
              %a.inspect,
              "to be", "{% if bool %}truthy{% else %}falsey{% end %}"
            ), {{file}}, {{line}})
          end
        {% end %}
      {% end %}
    end

    # An alternative way to spell "it" to more naturally describe tests with a name, not an action
    def test(description = "", file = __FILE__, line = __LINE__, &block)
      it(description, file, line, &block)
    end
  end

  module ObjectExtensions
    # Check if the other number is close to this one
    #
    # Returns true if the numbers are within the relative or the absolute tolerance of each other
    def close?(other, rel_tol = 1e-7, abs_tol = 0.0)
      result = 0

      if rel_tol < 0.0 || abs_tol < 0.0
        raise ArgumentError.new("Tolerances can't be negative")
      end

      return true if self == other

      if responds_to? :infinite?
        return false if infinite?
      end
      if other.responds_to? :infinite?
        return false if other.infinite?
      end

      diff = (other - self).abs

      diff <= (rel_tol * self).abs ||
      diff <= (rel_tol * other).abs ||
      diff <= abs_tol
    end
  end

  class NestedContext
    def report(result)
      # Use slash to separate test contexts, not just a space
      description = @description
      description += " / #{result.description}" unless result.description.empty?
      @parent.report Result.new(
        result.kind, description,
        result.file, result.line, result.elapsed, result.exception
      )
    end
  end
end
