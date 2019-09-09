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
      build_embedded: true,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LamPIaoCNC, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"} 
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_mcp3xxx, github: "brunosantanaa/ex_mcp3xxx"},
      {:gcode, github: "brunosantanaa/gcode"},
      {:poison, "~> 4.0"}
    ]
  end
end
