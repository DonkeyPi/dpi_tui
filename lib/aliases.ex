defmodule Dpi.Tui.Aliases do
  defmacro __using__(_) do
    quote do
      alias Dpi.Tui.Control
      alias Dpi.Tui.Checkbox
      alias Dpi.Tui.Select
      alias Dpi.Tui.Button
      alias Dpi.Tui.Frame
      alias Dpi.Tui.Input
      alias Dpi.Tui.Label
      alias Dpi.Tui.Panel
      alias Dpi.Tui.Radio
      alias Dpi.Tui.Theme
    end
  end
end
