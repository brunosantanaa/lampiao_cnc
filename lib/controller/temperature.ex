defmodule LamPIaoCNC.Temperature do
  use GenServer
  alias LamPIaoCNC.Settings
  alias Circuits.GPIO

  @time_to_read 10_000
  @temp_hister 5

  def start_link(conf) do
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  def init(_conf) do
    {:ok, _sensor} = ExMCP3xxx.start_link(family: 3202)

    {:ok, settings} = get_settings()

    {:ok, hotend_pin} = GPIO.open(settings.extruder.hotend_pin, :output)
    {:ok, heatbed_pin} = GPIO.open(settings.heatbed.pin, :output)

    state = %{pins: %{hotend: hotend_pin, heatbed: heatbed_pin}}
    Process.send_after(__MODULE__, :control, @time_to_read)
    {:ok, state}
  end

  def handle_info(:control, state) do
    {:ok, heatbed, extruder} = get()

    {:ok, settings} = get_settings()

    if(heatbed < settings.heatbed.temp + @temp_hister) do
      GPIO.write(state.pins.heatbed, 1)
    else
      GPIO.write(state.pins.heatbed, 0)
    end

    if(extruder < settings.extruder.temp + @temp_hister) do
      GPIO.write(state.pins.hotend, 1)
    else
      GPIO.write(state.pins.hotend, 0)
    end

    Process.send_after(__MODULE__, :control, @time_to_read)
    {:noreply, state}
  end

  defp get_settings do
    {:ok, settings} = Settings.read()

    extruder = settings.machine["extruder"] |> List.first()
    heatbed = settings.machine["heatbed"]

    thermistor_extruder = settings.thermistors[extruder["thermistor"]]
    thermistor_heatbed = settings.thermistors[heatbed["thermistor"]]

    {:ok,
     %{
       extruder: %{
         hotend_pin: extruder["hotend"],
         thermistor: thermistor_extruder,
         temp: extruder["temperature"],
         sensor: extruder["sense_ch"]
       },
       heatbed: %{
         pin: heatbed["pin"],
         thermistor: thermistor_heatbed,
         temp: heatbed["temperature"],
         sensor: heatbed["sense_ch"]
       }
     }}
  end

  defp get() do
    {:ok, settings} = get_settings()

    {:ok, heatbed_r} = ExMCP3xxx.read(settings.heatbed.sensor)
    {:ok, extruder_r} = ExMCP3xxx.read(settings.extruder.sensor)

    heatbed_temp = convert(settings.heatbed.thermistor, heatbed_r)
    extruder_temp = convert(settings.extruder.thermistor, extruder_r)

    {:ok, heatbed_temp, extruder_temp}
  end

  defp convert(therm_map, value, max \\ 0, min \\ 0, recur \\ false) do
    case Map.fetch(therm_map, Integer.to_string(value)) do
      {:ok, res} ->
        {:ok, res}

      :error ->
        unless recur do
          convert(therm_map, value, value + 1, value - 1, true)
        else
          case Map.fetch(therm_map, Integer.to_string(max)) do
            {:ok, n_max} ->
              case Map.fetch(therm_map, Integer.to_string(min)) do
                {:ok, n_min} ->
                  result = n_min + (value - min) * (n_min - n_max) / (min - max)
                  {:ok, result}

                :error ->
                  convert(therm_map, value, max, min - 1, true)
              end

            :error ->
              case Map.fetch(therm_map, Integer.to_string(min)) do
                {:ok, _n_min} -> convert(therm_map, value, max + 1, min, true)
                :error -> convert(therm_map, value, max + 1, min - 1, true)
              end
          end
        end
    end
  end
end
