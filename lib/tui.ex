defmodule Ash.Tui do
  defmacro __using__(_opts) do
    quote do
      import Ash.Tui.Macros
      use Ash.Tui.Colors
    end
  end
end
