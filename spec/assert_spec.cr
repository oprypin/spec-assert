require "./spec_helper"

describe "assert" do
  describe "failures" do
    fail 1 == 2, %{
      expected  1
         to ==  2
    }
    fail !(1 != 2), %{
       expected  1
      not to !=  2
    }
    fail 1 > 2, %{
      expected  1
       to be >  2
    }
    fail !(1 <= 2), %{
          expected  1
      not to be <=  2
    }
    fail "a" =~ /b/, %{
      expected  "a"
      to match  /b/
    }
    fail "a" !~ /a/, %{
          expected  "a"
      not to match  /a/
    }
    fail !("a" =~ /a/), %{
          expected  "a"
      not to match  /a/
    }
    fail !("a" !~ /b/), %{
      expected  "a"
      to match  /b/
    }
    fail 5.nil?, %{
      expected  5
       to be a  Nil
    }
    fail 5.is_a?(Float32), %{
      expected  5
       to be a  Float32
    }
    fail !5.is_a?(Int32), %{
         expected  5
      not to be a  Int32
    }
    fail ["a"].same?(["a"]), %r{
      expected  \["a"\]  @ 0x\w+
         to be  \["a"\]  @ 0x\w+
    }
    a = ["a"]
    fail !a.same?(a), %r{
       expected  \["a"\]  @ (0x\w+)
      not to be  \["a"\]  @ \1
    }
    fail [7].includes?(-7), %{
        expected  [7]
      to include  -7
    }
    fail !5, %{
      expected  5
         to be  falsey
    }
  end

  describe "successes" do
    check 2 != 5

    check !(2 > 5)

    check !("a" =~ /b/)

    check nil.nil?

    check 5.is_a? Int32

    check !(["a"].same? ["a"])

    check [7].includes? 7

    check true
  end

  describe "close?" do
    check 1.close? 1.00000001

    fail 1.0.close? 5.0
  end
end
