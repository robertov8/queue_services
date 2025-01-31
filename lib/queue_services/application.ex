defmodule QueueServices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {QueueServices.QueueGenserver,
       [ttl_expires_seconds: 20, function_to_dispatch: &QueueServices.greet/1]},
      {QueueServices.QueueGenserverPartitionSupervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: QueueServices.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
