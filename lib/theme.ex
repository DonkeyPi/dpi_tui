defmodule Dpi.Tui.Theme do
  use Dpi.Tui.Aliases
  use Dpi.Tui.Colors

  # Mandatory selector props:
  #  - id      - Node id (not full path).
  #  - type    - Node type: Button, Label, ...
  #  - class   - Arbitrary qualifier.
  #  - enabled - Enable flag.
  #  - focused - Focus flag.
  #  - valid   - Valid flag (Input).
  # FIXME Future selector props:
  #  - hovered - Hover flag.
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
    selector = Map.put(selector, :valid, module.valid(model))

    cond do
      is_function(theme, 3) -> fn item, type -> theme.(item, type, selector) end
      is_atom(theme) -> fn item, type -> theme.get_style(item, type, selector) end
    end
  end

  def get_style(item, type, selector) do
    gets(item, type, selector)
  end

  defp getp(dest, src, name, def) do
    value = Map.get(src, name, def)
    Map.put(dest, name, value)
  end

  def gets(:fore, _, %{class: %{fore: fore}}), do: fore
  def gets(:back, _, %{class: %{back: back}}), do: back

  def gets(:fore, _, %{type: Label, class: :info}), do: 0x0F
  def gets(:fore, _, %{type: Label, class: :error}), do: 0x0F
  def gets(:fore, _, %{type: Label, class: :success}), do: 0x0F
  def gets(:back, _, %{type: Label, class: :info}), do: 0xEA
  def gets(:back, _, %{type: Label, class: :error}), do: 0x7C
  def gets(:back, _, %{type: Label, class: :success}), do: 0x16

  def gets(:back, _, %{type: Frame}), do: nil
  def gets(:back, _, %{type: Panel}), do: nil
  def gets(:back, _, %{type: Label}), do: nil
  def gets(:fore, _, %{type: Label}), do: 0xF6
  def gets(:back, _, %{type: Button, focused: true, class: :danger}), do: 0x7C
  def gets(:fore, _, %{type: Button, focused: true}), do: 0x0F
  def gets(:back, _, %{type: Button, focused: true}), do: 0x16
  def gets(:fore, _, %{type: Checkbox, focused: true}), do: 0x0F
  def gets(:back, _, %{type: Checkbox, focused: true}), do: 0x16

  def gets(:fore, _, %{type: Input, enabled: true, focused: true}), do: 0x0F
  def gets(:fore, _, %{type: Input, enabled: true}), do: 0x07

  def gets(:back, :selected, %{type: Input, enabled: true, focused: true, valid: true}), do: 0x1C
  def gets(:back, :selected, %{type: Input, enabled: true, focused: true, valid: false}), do: 0xA0
  def gets(:back, _, %{type: Input, enabled: true, focused: true, valid: true}), do: 0x16
  def gets(:back, _, %{type: Input, enabled: true, focused: true, valid: false}), do: 0x7C
  def gets(:back, _, %{type: Input, enabled: true, focused: false, valid: false}), do: 0x34
  def gets(:back, _, %{type: Input, enabled: true}), do: 0xEA

  def gets(:fore, :selected, %{enabled: true, focused: true}), do: 0x0F
  def gets(:back, :selected, %{enabled: true, focused: true}), do: 0x16
  def gets(:back, :selected, %{enabled: true, focused: false}), do: 0xEF

  def gets(:fore, _, %{enabled: true}), do: 0x07
  def gets(:fore, _, _), do: @dpi_def_fore
  def gets(:back, _, _), do: @dpi_def_back
end
