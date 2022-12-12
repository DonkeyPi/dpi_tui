defmodule Ash.Tui do
  alias Ash.Tui.Theme

  defmacro __using__(_opts) do
    quote do
      use Ash.Tui.Colors
      import Ash.Tui.Macros
      import Ash.Tui
    end
  end

  def set_theme(theme) do
    Theme.set(theme)
  end

  def get_style(prop, selector) do
    Theme.get_style(prop, selector)
  end
end
