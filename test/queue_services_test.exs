defmodule QueueServicesTest do
  use ExUnit.Case
  doctest QueueServices

  test "greets the world" do
    assert QueueServices.hello() == :world
  end
end
