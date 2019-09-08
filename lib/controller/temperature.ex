defmodule LamPIaoCNC.Temperature do
  use GenServer
  alias LamPIaoCNC.Settings

  @time_to_read 10_000

  def start_link(conf) do
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  def init(_conf) do
    {:ok, _sensor} = ExMCP3xxx.start_link(family: 3202)
    {:ok, machine_settings} = Settings.read()

    extruder = machine_settings["extruder"] |> List.first()
    heatbed = machine_settings["heatbed"]

    state = %{extruder: extruder, heatbed: heatbed}
    Process.send_after(__MODULE__, :control, 1_000)
    {:ok, state}
  end

  def handle_info(:control, state) do
    {:ok, heatbed_r} = ExMCP3xxx.read(state.heatbed["sense_ch"])
    {:ok, extruder_r} = ExMCP3xxx.read(state.extruder["sense_ch"])
    heatbed_temp = get_temperature(heatbed_r)
    extruder_temp = get_temperature(extruder_r)


    Process.send_after(__MODULE__, :control, @time_to_read)
    {:noreply, state}
  end

  defp get_temperature(voltage) do
    
  end
end
