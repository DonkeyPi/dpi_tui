defmodule Ash.Tui.Theme do
  use Ash.Tui.Aliases
  use Ash.Tui.Colors

  # Mandatory props
  # id      - Node id.
  # type    - Node type: Button, Label, ...
  # class   - Arbitrary qualifier.
  # enabled - Enable flag.
  # focused - Focus flag.
  # hovered - Hover flag.
  # invalid - Nil or invalid reason.
  @callback color(name :: any, style :: map()) :: color :: any()

  def set(theme), do: Process.put(__MODULE__, theme)

  def get(id, module, model) do
    theme = Process.get(__MODULE__, __MODULE__)
    # FIXME allow per node theme override
    # theme = Map.get(model, :theme, theme)
    style = %{type: module, id: id}
    style = getp(style, model, :enabled, true)
    style = getp(style, model, :focused, false)
    style = getp(style, model, :class, nil)
    # FIXME add id path
    # FIXME implement extra styles
    # style = getp(style, model, :hovered, nil)
    # style = getp(style, model, :invalid, nil)

    cond do
      is_function(theme, 2) -> fn name -> theme.(name, style) end
      is_atom(theme) -> fn name -> theme.color(name, style) end
    end
  end

  defp getp(dest, src, name, def) do
    value = Map.get(src, name, def)
    Map.put(dest, name, value)
  end

  def color({:fore, _}, %{type: Button}), do: @red
  def color({:back, _}, %{type: Button}), do: @blue
  def color({:fore, _}, _), do: @white
  def color({:back, _}, _), do: @black
end
