defmodule LoadbalancerTest do
  use ExUnit.Case
  doctest Loadbalancer

  test "greets the world" do
    assert Loadbalancer.hello() == :world
  end
end
