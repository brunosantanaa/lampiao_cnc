defmodule LamPIaoCNC.Supervisor do
  
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    children = [
      LamPIaoCNC.Settings
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end