defmodule Ash.Tui do
  defmacro __using__(_opts) do
    quote do
      alias Ash.Tui.Checkbox
      alias Ash.Tui.Select
      alias Ash.Tui.Button
      alias Ash.Tui.Frame
      alias Ash.Tui.Input
      alias Ash.Tui.Label
      alias Ash.Tui.Panel
      alias Ash.Tui.Radio
      alias Ash.Tui.Theme
      use Ash.Tui.Const
    end
  end
end
