defmodule Ash.Tui.Theme do
  use Ash.Tui.Aliases
  use Ash.Tui.Colors

  # Mandatory selector props:
  #  - id      - Node id (not full path).
  #  - type    - Node type: Button, Label, ...
  #  - class   - Arbitrary qualifier.
  #  - enabled - Enable flag.
  #  - focused - Focus flag.
  # Future selector props:
  #  - hovered - Hover flag.
  #  - invalid - Nil or invalid reason.
  @callback get_style(prop :: any, selector :: map()) :: color :: any()

  def set(theme), do: Process.put(__MODULE__, theme)

  def get(id, module, model) do
    # Module level theme override wont be supported.
    theme = Process.get(__MODULE__, __MODULE__)
    # Path [id | tail] selector wont be supported.
    selector = %{type: module, id: id}
    # Convenience breaks encapsulation, the alternative
    # is a selector getter to return all involved props.
    selector = getp(selector, model, :enabled, true)
    selector = getp(selector, model, :focused, false)
    selector = getp(selector, model, :class, nil)
    # FIXME implement extra selectors
    # selector = getp(selector, model, :hovered, nil)
    # selector = getp(selector, model, :invalid, nil)

    cond do
      is_function(theme, 2) -> fn prop -> theme.(prop, selector) end
      is_atom(theme) -> fn prop -> theme.get_style(prop, selector) end
    end
  end

  def get_style(prop, selector) do
    # IO.inspect({prop, selector, calc_style(prop, selector)})
    calc_style(prop, selector)
  end

  defp getp(dest, src, name, def) do
    value = Map.get(src, name, def)
    Map.put(dest, name, value)
  end

  def calc_style({:fore, _}, %{enabled: false}), do: @black2
  def calc_style({:back, _}, %{enabled: false}), do: @black
  def calc_style({:fore, _}, %{type: Button, focused: true}), do: @white
  def calc_style({:back, _}, %{type: Button, focused: true}), do: @blue
  def calc_style({:fore, _}, %{type: Input, focused: true}), do: @white
  def calc_style({:back, _}, %{type: Input, focused: true}), do: @blue
  def calc_style({:fore, _}, %{type: Checkbox, focused: true}), do: @white
  def calc_style({:fore, :selected}, %{type: Select}), do: @white
  def calc_style({:fore, :selected}, %{type: Radio}), do: @white
  def calc_style({:fore, _}, _), do: @black2
  def calc_style({:back, _}, _), do: @black
end
