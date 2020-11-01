defmodule PrimyTest do
  use ExUnit.Case
  doctest Primy

  test "greets the world" do
    assert Primy.hello() == :world
  end
end
