defmodule Sample.MixProject do
  use Mix.Project

  def project do
    [
      app: :sample,
      version: "0.1.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Sample.App, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ash_tui, path: ".."},
      {:ash_app, path: "../../ash_app"},
      {:ash_tool, path: "../../ash_tool"},
      {:ash_input, path: "../../ash_input"},
      {:ash_tui_drv, path: "../../ash_tui_drv"}
    ]
  end
end
