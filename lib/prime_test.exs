defmodule Primy.PrimeTest do
  use ExUnit.Case
  alias Primy.Prime

  describe "is_prime?/1" do
    test "returns true if the integer is a prime number" do
      assert Prime.is_prime?(3)
      assert Prime.is_prime?(5)
      assert Prime.is_prime?(7703)
    end

    test "returns false if the integer isn't a prime number" do
      refute Prime.is_prime?(0)
      refute Prime.is_prime?(4)
      refute Prime.is_prime?(7704)
    end

    test "raise an error if given a negative integer" do
      assert_raise ArgumentError, fn -> Prime.is_prime?(-100) end
    end

    test "raise an error if given a non integer" do
      assert_raise ArgumentError, fn -> Prime.is_prime?("5") end
    end
  end
end
