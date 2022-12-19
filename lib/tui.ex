defmodule Ash.Tui do
  alias Ash.React.App
  alias Ash.Tui.Theme
  alias Ash.Tui.Term

  defmacro __using__(_opts) do
    quote do
      use Ash.Tui.Colors
      import Ash.Tui.Macros
      import Ash.Tui
    end
  end

  def set_handler(handler) do
    App.set_handler(handler)
  end

  def set_theme(theme) do
    Theme.set(theme)
  end

  def get_style(item, type, selector) do
    Theme.get_style(item, type, selector)
  end

  def get_prop(name, value \\ nil) do
    Process.get({__MODULE__, :prop, name}, value)
  end

  def put_prop(name, value) do
    Process.put({__MODULE__, :prop, name}, value)
  end

  def pop_prop(name) do
    Process.delete({__MODULE__, :prop, name})
  end

  def set_title(title) do
    Term.set_title(title)
  end
end
