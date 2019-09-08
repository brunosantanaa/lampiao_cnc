defmodule LamPIaoCNC.ChopperNif do
  @on_load {:load_nif, 0}
  @compile {:autoload, false}

  def load_nif() do
    nif_binary = Application.app_dir(:lampiao_cnc, "priv/chopper_motion")

    :erlang.load_nif(to_charlist(nif_binary), 0)
  end

  def motion(_axes, _dir_axes, _pin_clk_axes, _pin_dir_axes, _ion_axes, _ioff_axes),
    do: :erlang.nif_error(:nif_not_loaded)

  def init_motor(_pins), do: :erlang.nif_error(:nif_not_loaded)
end
