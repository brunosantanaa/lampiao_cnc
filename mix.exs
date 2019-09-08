defmodule LamPIaoCNC.MixProject do
  use Mix.Project

  def project do
    [
      app: :lampiao_cnc,
      version: "0.1.0",
      elixir: "~> 1.8",
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:gcode, github: "brunosantanaa/gcode"},
      {:elixir_make, "~> 0.5", runtime: false},
      {:ex_mcp3xxx, github: "brunosantanaa/ex_mcp3xxx"},
      {:poison, "~> 4.0"}
    ]
  end
end
