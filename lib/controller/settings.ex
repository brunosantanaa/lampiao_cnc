defmodule LamPIaoCNC.Settings do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def read, do: GenServer.call(__MODULE__, :read)

  def init(_conf) do
    {:ok, state} =
      with {:ok, body} <- :lampiao_cnc |> Application.app_dir("priv/settings/settings.json") |> File.read(),
           {:ok, conf_json} <- Poison.decode(body),
           do: {:ok, conf_json}

    {:ok, state}
  end

  def handle_call(:read, _from, state) do
    {:reply, {:ok, state}, state}
  end
end
