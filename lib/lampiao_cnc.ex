defmodule LamPIaoCNC do
  @moduledoc """
  Documentation for LamPIaoCNC.
  """

  use Application

  @doc """
  Hello world.

  ## Examples

      iex> LamPIaoCNC.hello()
      :world

  """
  @impl true
  def start(_type, _args) do
    LamPIaoCNC.Supervisor.start_link(name: LamPIaoCNC.Supervisor)
  end
end
