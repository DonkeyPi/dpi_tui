defmodule Ash.Tui do
  alias Ash.Tui.Theme

  defmacro __using__(_opts) do
    quote do
      import Ash.Tui.Macros
      import Ash.Tui
      use Ash.Tui.Colors
    end
  end

  def set_theme(theme) do
    Theme.set(theme)
  end
end
