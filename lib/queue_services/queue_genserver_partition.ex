defmodule QueueServices.QueueGenserverPartition do
  use GenServer

  require Logger

  def start_link(opts) do
    Logger.info("Starting QueueGenserverPartition with opts: #{inspect(opts)}")

    GenServer.start_link(__MODULE__, opts)
  end

  def enqueue(pid, item) do
    Logger.info("Enqueuing item #{inspect(item)} into partition #{inspect(pid)}")
    GenServer.cast(pid, {:enqueue, item})
  end

  def get_queue(pid) do
    GenServer.call(pid, :get_queue)
  end

  def init(opts) do
    ttl_expires_seconds = Keyword.get(opts, :ttl_expires_seconds, 10)
    function_to_dispatch = Keyword.get(opts, :function_to_dispatch)

    initial_state = %{
      queue: [],
      ttl_expires_seconds: ttl_expires_seconds,
      current_ttl_seconds: 0,
      function_to_dispatch: function_to_dispatch
    }

    schedule_monitor()

    {:ok, initial_state}
  end

  def handle_cast({:enqueue, items}, state) when is_list(items) do
    new_queue = state.queue ++ items
    {:noreply, %{state | queue: new_queue}}
  end

  def handle_cast({:enqueue, item}, state) do
    new_queue = [item | state.queue]
    {:noreply, %{state | queue: new_queue}}
  end

  def handle_call(:get_queue, _from, state) do
    {:reply, state.queue, state}
  end

  # If the queue is empty, we don't need to monitor it
  def handle_info(:monitor, %{queue: []} = state) do
    # Logger.info("Queue is empty, not monitoring")
    schedule_monitor()

    {:noreply, state}
  end

  def handle_info(:monitor, state) do
    schedule_monitor()

    current_ttl_seconds = state.current_ttl_seconds + 1

    # Dispatch queue if ttl has reached
    ttl_reached = current_ttl_seconds >= state.ttl_expires_seconds

    if ttl_reached do
      new_state = %{state | current_ttl_seconds: 0, queue: []}
      # Logger.info("Monitoring timeout: #{inspect(new_state)}")

      send(self(), {:dispatch_queue, state.queue})

      {:noreply, new_state}
    else
      new_state = %{state | current_ttl_seconds: current_ttl_seconds}
      # Logger.info("No items to dispatch")

      {:noreply, new_state}
    end
  end

  def handle_info({:dispatch_queue, queue}, state) do
    # Logger.info("Dispatching queue #{inspect(queue)}")

    if is_function(state.function_to_dispatch) do
      state.function_to_dispatch.(queue)
    else
      Logger.error("Function to dispatch is not a function")
    end

    # TODO: Send a to the queue service

    {:noreply, state}
  end

  defp schedule_monitor() do
    # Logger.info("Scheduling monitor for 1s")

    Process.send_after(self(), :monitor, :timer.seconds(1))
  end
end
