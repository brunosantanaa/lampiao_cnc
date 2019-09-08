defmodule LamPIaoCNC.Motion do
  use GenServer

  @doc """
  LamPIaoCNC.Motion.start_link([pin_clk: [x: 10, y: 11], pin_dir: [x: 9, y: 12], interval_on: [x: 500, y: 500], interval_off: [x: 500, y: 500]])
  """
  def start_link(conf) do
    GenServer.start_link(__MODULE__, conf ++ [callback: self()], name: __MODULE__)
  end

  @doc """
  LamPIaoCNC.Motion.line([4, 8], [0, 1], [:x, :y])
  """
  def line(steps, dir, axes),
    do: GenServer.call(__MODULE__, {:line, steps, dir, axes})

  def init(conf) do
    state = %{
      pin_clk: conf[:pin_clk],
      pin_dir: conf[:pin_dir],
      interval_on: conf[:interval_on],
      interval_off: conf[:interval_off]
    }

    {:ok, state}
  end

  def handle_call({:line, steps, dir, axes}, _from, state) do
    dim = Enum.max(steps)
    bres = steps |> Enum.map(fn s -> dim |> bres_line(s) end)

    pins_clk = axes |> Enum.map(fn c -> state.pin_clk[c] end)
    pins_dir = axes |> Enum.map(fn c -> state.pin_dir[c] end)
    intervals_on = axes |> Enum.map(fn c -> state.interval_on[c] end)
    intervals_off = axes |> Enum.map(fn c -> state.interval_off[c] end)

    LamPIaoCNC.ChopperNif.motion(bres, dir, pins_clk, pins_dir, intervals_on, intervals_off)
    {:reply, bres, state}
  end

  defp bres_line(dimension, value, x \\ 0, y \\ 0, p \\ [], resp \\ []) do
    p2 = 2 * value
    xy2 = 2 * (value - dimension)

    if p == [] do
      p = 2 * value - dimension
      bres_line(dimension, value, 0, 0, p, [])
    else
      if x < dimension do
        if p < 0 do
          bres_line(dimension, value, x + 1, y, p + p2, resp ++ [y])
        else
          bres_line(dimension, value, x + 1, y + 1, p + xy2, resp ++ [y + 1])
        end
      else
        resp
      end
    end
  end

  defp bres_curve() do
    nil
  end
end
