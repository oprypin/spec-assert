require "spec"

module Spec
  module DSL
    # Check that the expression is true, or raise AssertionError otherwise
    macro assert(exp, file = __FILE__, line = __LINE__, bool = true)
      {% if exp.is_a?(Not) %}
        # undefined macro method 'Not#exp' :(
        assert({{exp.stringify[1..-1].id}}, {{file}}, {{line}}, {{!bool}})
      {% else %}
        {% call = exp.is_a?(Call) && (obj = exp.receiver) && !exp.args.empty? && (arg = exp.args[0]) %}
        {% if bool %}
          {% should = "should".id %}
        {% else %}
          {% should = "should_not".id %}
        {% end %}
        {% if call && exp.name == "==" %}
          ({{obj}}).{{should}}(eq({{arg}})
        {% elsif call && exp.name == "!=" %}
          ({{obj}}).should{% if bool %}_not{% end %}(eq({{arg}})
        {% elsif call && (exp.name == ">" || exp.name == ">=" || exp.name == "<" || exp.name == "<=") %}
          ({{obj}}).{{should}}(be.{{exp.name.id}}({{arg}})
        {% elsif call && exp.name == "=~" %}
          ({{obj}}).{{should}}(match({{arg}})
        # IsA is gimped in macros :(
        # elsif exp.is_a?(IsA)
        #  (exp.obj).should(be_a(exp.const)
        {% elsif call && exp.name == "same?" %}
          ({{obj}}).{{should}}(be({{arg}})
        {% elsif call && exp.name == "includes?" %}
          ({{obj}}).{{should}}(contain({{arg}})
        {% else %}
          ({{exp}}).should(be_{% if bool %}truthy{% else %}falsey{% end %}
        {% end %}, {{file}}, {{line}})
      {% end %}
    end

    # An alternative way to spell "it" to more naturally describe tests with a name, not an action
    def test(description = " ", file = __FILE__, line = __LINE__, &block)
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
