defmodule Ash.Tui do
  defmacro __using__(_opts) do
    quote do
      alias Ash.Tui.Button
      alias Ash.Tui.Checkbox
      alias Ash.Tui.Frame
      alias Ash.Tui.Input
      alias Ash.Tui.Label
      alias Ash.Tui.Panel
      alias Ash.Tui.Radio
    end
  end
end
