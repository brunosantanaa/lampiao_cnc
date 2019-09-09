defmodule LamPIaoCNC.Temperature do
  use GenServer
  alias LamPIaoCNC.Settings

  @time_to_read 10_000

  def start_link(conf) do
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  def att_settings, do: GenServer.cast(__MODULE__, :settings)

  def init(_conf) do
    {:ok, _sensor} = ExMCP3xxx.start_link(family: 3202)

    {:ok, state} = get_settings()

    Process.send_after(__MODULE__, :control, @time_to_read)
    {:ok, state}
  end

  def handle_cast(:settings, _state) do
    # TODO
    {:ok, new_state} = get_settings()
    {:noreply, new_state}
  end

  def handle_info(:control, state) do
    {:ok, heatbed_r} = ExMCP3xxx.read(state.heatbed["sense_ch"])
    {:ok, extruder_r} = ExMCP3xxx.read(state.extruder["sense_ch"])

    _heatbed_temp = get_temperature(state.heatbed.thermistor, heatbed_r)
    _extruder_temp = get_temperature(state.extruder.thermistor, extruder_r)

    Process.send_after(__MODULE__, :control, @time_to_read)
    {:noreply, state}
  end

  defp get_settings do
    {:ok, settings} = Settings.read()

    extruder = settings.machine["extruder"] |> List.first()
    heatbed = settings.machine["heatbed"]

    thermistor_extruder = settings.thermistors[extruder["thermistor"]]
    thermistor_heatbed = settings.thermistors[heatbed["thermistor"]]

    pin_extruder = extruder["hotend"]
    pin_heatbed = heatbed["pin"]

    {:ok,
     %{
       extruder: %{pin: pin_extruder, thermistor: thermistor_extruder},
       heatbed: %{pin: pin_heatbed, thermistor: thermistor_heatbed}
     }}
  end

  defp get_temperature(therm_map, value, max \\ 0, min \\ 0, recur \\ false) do
    case Map.fetch(therm_map, Integer.to_string(value)) do
      {:ok, res} ->
        {:ok, res}

      :error ->
        unless recur do
          get_temperature(therm_map, value, value + 1, value - 1, true)
        else
          case Map.fetch(therm_map, Integer.to_string(max)) do
            {:ok, n_max} ->
              case Map.fetch(therm_map, Integer.to_string(min)) do
                {:ok, n_min} ->
                  result = n_min + (value - min) * (n_min - n_max) / (min - max)
                  {:ok, result}

                :error ->
                  get_temperature(therm_map, value, max, min - 1, true)
              end

            :error ->
              case Map.fetch(therm_map, Integer.to_string(min)) do
                {:ok, _n_min} -> get_temperature(therm_map, value, max + 1, min, true)
                :error -> get_temperature(therm_map, value, max + 1, min - 1, true)
              end
          end
        end
    end
  end
end
