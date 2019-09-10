defmodule LamPIaoCNC.Settings do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def read, do: GenServer.call(__MODULE__, :read)

  def change(file, new_values), do: GenServer.cast(__MODULE__, {:change, file, new_values})

  def att, do: GenServer.cast(__MODULE__, :att)

  def init(_conf) do
    {:ok, state} = get_settings()

    {:ok, state}
  end

  def handle_call(:read, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast(:att, _state) do
    {:ok, new_state} = get_settings()
    {:noreply, new_state}
  end
  
  def handle_cast({:change, file, new_values}, state) do
    new_content = Poison.encode!(Map.merge(state[file], new_values))

    :lampiao_cnc
    |> Application.app_dir("priv/settings/#{Atom.to_string(file)}.json")
    |> File.write(new_content)

    {:ok, new_state} = get_settings()
    {:noreply, new_state}
  end

  defp get_settings do
    {:ok, machine} =
      with {:ok, body} <-
             :lampiao_cnc |> Application.app_dir("priv/settings/machine.json") |> File.read(),
           {:ok, conf_json} <- Poison.decode(body),
           do: {:ok, conf_json}

    {:ok, thermistors} =
      with {:ok, body} <-
             :lampiao_cnc |> Application.app_dir("priv/settings/thermistors.json") |> File.read(),
           {:ok, conf_json} <- Poison.decode(body),
           do: {:ok, conf_json}

    {:ok, %{machine: machine, thermistors: thermistors}}
  end
end
