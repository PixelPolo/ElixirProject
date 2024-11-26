defmodule CdnTest do
  use ExUnit.Case
  doctest Cdn

  test "greets the world" do
    assert Cdn.hello() == :world
  end
end
