defmodule Playground do
  def run do
    for i <- 1..10 do
      router_key = if rem(i, 2) == 0, do: 2, else: 1

      QueueServices.QueueGenserverPartitionSupervisor.enqueue(router_key, i)
    end
  end
end
