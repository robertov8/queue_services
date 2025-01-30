defmodule QueueServices do
  @moduledoc """
  Documentation for `QueueServices`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> QueueServices.hello()
      :world

  """
  def greet(items) do
    IO.puts("Hello, World!: #{inspect(items)}")
  end
end
