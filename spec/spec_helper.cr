require "../src/spec_assert.cr"


def trim(msg)
  lines = msg.lines.map(&.rstrip).reject(&.empty?)
  while lines.all? &.starts_with?(" ")
    lines.map! &.[1..-1]
  end
  lines.join('\n')
end

def trim(msg : Regex)
  Regex.new(trim(msg.source), msg.options)
end


macro fail(exp, msg = nil)
  test do
    expect_raises Spec::AssertionFailed{% if msg %}, trim({{msg}}){% end %} do
      assert {{exp}}
    end
  end
end

macro check(exp)
  test do
    assert {{exp}}
  end
end
