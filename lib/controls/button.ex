defmodule Ash.Tui.Button do
  @behaviour Ash.Tui.Control
  use Ash.Tui.Events
  use Ash.Tui.Colors
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Button
  alias Ash.Tui.Canvas
  alias Ash.Tui.Theme

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {String.length(text) + 2, 1})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    theme = Map.get(opts, :theme, :default)
    shortcut = Map.get(opts, :shortcut, nil)
    on_click = Map.get(opts, :on_click, &Button.nop/0)

    model = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      theme: theme,
      text: text,
      shortcut: shortcut,
      on_click: on_click
    }

    check(model)
  end

  def nop(), do: :nop

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_click: cb}) when not is_function(cb, 0), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def focused(%{focused: focused}), do: focused
  def focused(model, focused), do: %{model | focused: focused}
  def refocus(model, _), do: model
  def findex(%{findex: findex}), do: findex
  def shortcut(%{shortcut: shortcut}), do: shortcut
  def children(_), do: []
  def children(model, _), do: model
  def modal(_), do: false

  def update(model, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused])
    props = Control.coalesce(props, :on_click, &Button.nop/0)
    model = Control.merge(model, props)
    check(model)
  end

  def handle(model, @ev_kp_fprev), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_fnext), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kdown), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kright), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kleft), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_kup), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_enter), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_trigger), do: trigger(model)
  def handle(model, @ev_mp_left), do: trigger(model)
  def handle(%{shortcut: shortcut} = model, {:shortcut, shortcut}), do: trigger(model)
  def handle(model, _event), do: {model, nil}

  def render(model, canvas) do
    %{
      text: text,
      theme: theme,
      focused: focused,
      size: {cols, rows},
      enabled: enabled
    } = model

    theme = Theme.get(theme)

    canvas =
      case {enabled, focused} do
        {false, _} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_disabled)
          Canvas.color(canvas, :back, theme.back_disabled)

        {true, true} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_focused)
          Canvas.color(canvas, :back, theme.back_focused)

        _ ->
          canvas = Canvas.color(canvas, :fore, theme.fore_editable)
          Canvas.color(canvas, :back, theme.back_editable)
      end

    line = String.duplicate(" ", cols)

    canvas =
      for r <- 0..(rows - 1), reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          Canvas.write(canvas, line)
      end

    # center vertically and horizontally
    offy = div(rows - 1, 2)

    canvas = Canvas.move(canvas, 0, offy)
    canvas = Canvas.write(canvas, "[")
    canvas = Canvas.move(canvas, cols - 1, offy)
    canvas = Canvas.write(canvas, "]")
    offset = div(cols - String.length(text), 2)
    canvas = Canvas.move(canvas, offset, offy)
    Canvas.write(canvas, text)
  end

  defp trigger(%{on_click: on_click} = model) do
    {model, {:click, on_click.()}}
  end

  defp check(model) do
    Check.assert_boolean(:focused, model.focused)
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_boolean(:enabled, model.enabled)
    Check.assert_gte(:findex, model.findex, -1)
    Check.assert_atom(:theme, model.theme)
    Check.assert_string(:text, model.text)
    shortcuts = [nil | @shortcuts]
    Check.assert_in_list(:shortcut, model.shortcut, shortcuts)
    Check.assert_function(:on_click, model.on_click, 0)
    model
  end
end
