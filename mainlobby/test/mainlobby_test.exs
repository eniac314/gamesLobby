defmodule MainlobbyTest do
  use ExUnit.Case
  doctest Mainlobby

  test "greets the world" do
    assert Mainlobby.hello() == :world
  end
end
