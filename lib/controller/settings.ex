defmodule LamPIaoCNC.Settings do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def read, do: GenServer.call(__MODULE__, :read)

  def att, do: GenServer.cast(__MODULE__, :att)

  def init(_conf) do
    {:ok, state} = get_settings()

    {:ok, state}
  end

  def handle_call(:read, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast(:att, _state) do
    # TODO
    {:ok, new_state} = get_settings()
    {:noreply, new_state}
  end

  defp get_settings do
    {:ok, settings} =
      with {:ok, body} <-
             :lampiao_cnc |> Application.app_dir("priv/settings/machine.json") |> File.read(),
           {:ok, conf_json} <- Poison.decode(body),
           do: {:ok, conf_json}

    {:ok, thermistors} =
      with {:ok, body} <-
             :lampiao_cnc |> Application.app_dir("priv/settings/thermistors.json") |> File.read(),
           {:ok, conf_json} <- Poison.decode(body),
           do: {:ok, conf_json}

    {:ok, %{machine: settings, thermistors: thermistors}}
  end
end
