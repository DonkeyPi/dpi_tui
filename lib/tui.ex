defmodule Dpi.Tui do
  alias Dpi.Tui.Theme
  alias Dpi.Tui.Term

  defmacro __using__(_opts) do
    quote do
      use Dpi.Tui.Fonts
      use Dpi.Tui.Colors
      use Dpi.Tui.Layouts
      import Dpi.Tui.Macros
      import Dpi.Tui
    end
  end

  def set_theme(theme) do
    Theme.set(theme)
  end

  def get_style(item, type, selector) do
    Theme.get_style(item, type, selector)
  end

  # has no effect on rpiX
  def set_title(title) do
    Term.set_title(title)
  end

  # has no effect on host
  def set_layout(layout) do
    Term.set_layout(layout)
  end
end
