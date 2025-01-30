defmodule QueueServices.QueueGenserver do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def enqueue(item) do
    GenServer.cast(__MODULE__, {:enqueue, item})
  end

  def get_queue do
    GenServer.call(__MODULE__, :get_queue)
  end

  def init(opts) do
    timeout_monitor_seconds = Keyword.get(opts, :timeout_monitor_seconds, 1)
    ttl_expires_seconds = Keyword.get(opts, :ttl_expires_seconds, 10)
    max_queue_size = Keyword.get(opts, :max_queue_size, 10)
    function_to_dispatch = Keyword.get(opts, :function_to_dispatch)

    initial_state = %{
      queue: [],
      timeout_monitor_seconds: timeout_monitor_seconds,
      ttl_expires_seconds: ttl_expires_seconds,
      current_ttl_seconds: 0,
      max_queue_size: max_queue_size,
      function_to_dispatch: function_to_dispatch
    }

    schedule_monitor(timeout_monitor_seconds)

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

  def handle_info(:monitor, state) do
    schedule_monitor(state.timeout_monitor_seconds)

    current_ttl_seconds = state.current_ttl_seconds + state.timeout_monitor_seconds

    # Dispatch queue if it has items and either ttl has reached or queue has reached max size
    has_items = Enum.count(state.queue) > 0
    ttl_reached = current_ttl_seconds >= state.ttl_expires_seconds
    queue_full = Enum.count(state.queue) >= state.max_queue_size

    if has_items and (ttl_reached or queue_full) do
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

  defp schedule_monitor(timeout_monitor_seconds) do
    # Logger.info("Scheduling monitor for #{timeout_monitor_seconds}s")
    timeout_monitor_ms = :timer.seconds(timeout_monitor_seconds)

    Process.send_after(self(), :monitor, timeout_monitor_ms)
  end
end
