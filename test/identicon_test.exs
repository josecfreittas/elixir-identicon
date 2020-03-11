defmodule IdenticonTest do
  use ExUnit.Case
  doctest Identicon

  test "generate_icon" do
    assert Identicon.generate("Jane Doe") == :ok
  end
end
