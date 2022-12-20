defmodule Ash.Tui do
  alias Ash.Tui.Theme
  alias Ash.Tui.Term

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

  def get_style(item, type, selector) do
    Theme.get_style(item, type, selector)
  end

  def set_title(title) do
    Term.set_title(title)
  end
end
