defmodule Ash.Tui.Aliases do
  defmacro __using__(_) do
    quote do
      alias Ash.Tui.Control
      alias Ash.Tui.Checkbox
      alias Ash.Tui.Select
      alias Ash.Tui.Button
      alias Ash.Tui.Frame
      alias Ash.Tui.Input
      alias Ash.Tui.Label
      alias Ash.Tui.Panel
      alias Ash.Tui.Radio
      alias Ash.Tui.Theme
    end
  end
end
