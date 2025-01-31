defmodule QueueServices.QueueGenserverPartitionSupervisor do
  use Supervisor

  alias QueueServices.{QueueGenserverPartition, QueueGenserverPartitionSupervisor}

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [
      {PartitionSupervisor,
       partitions: 2,
       name: QueueGenserverPartitionSupervisor,
       child_spec:
         QueueGenserverPartition.child_spec(
           ttl_expires_seconds: 20,
           function_to_dispatch: &QueueServices.greet/1
         )}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def enqueue(router_key, item) do
    pid = {:via, PartitionSupervisor, {__MODULE__, router_key}}

    QueueGenserverPartition.enqueue(pid, item)
  end

  def partitions do
    PartitionSupervisor.partitions(__MODULE__)
  end

  def count_children do
    PartitionSupervisor.count_children(__MODULE__)
  end
end
