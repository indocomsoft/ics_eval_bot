defmodule IcsEvalBotTest do
  use ExUnit.Case
  doctest IcsEvalBot

  test "greets the world" do
    assert IcsEvalBot.hello() == :world
  end
end
