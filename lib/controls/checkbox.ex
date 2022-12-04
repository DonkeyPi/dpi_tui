defmodule Ash.Tui.Checkbox do
  @behaviour Ash.Tui.Control
  use Ash.Tui.Const
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Checkbox
  alias Ash.Tui.Canvas
  alias Ash.Tui.Theme

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {String.length(text) + 3, 1})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    theme = Map.get(opts, :theme, :default)
    checked = Map.get(opts, :checked, false)
    on_change = Map.get(opts, :on_change, &Checkbox.nop/1)

    state = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      theme: theme,
      text: text,
      checked: checked,
      on_change: on_change
    }

    check(state)
  end

  def nop(_), do: nil

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_change: nil}), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def focused(%{focused: focused}), do: focused
  def focused(state, focused), do: %{state | focused: focused}
  def refocus(state, _), do: state
  def findex(%{findex: findex}), do: findex
  def shortcut(_), do: nil
  def children(_), do: []
  def children(state, _), do: state
  def modal(_), do: false

  def update(state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused])
    props = Control.coalesce(props, :on_change, &Checkbox.nop/1)
    state = Control.merge(state, props)
    check(state)
  end

  def handle(state, %{type: :key, key: :tab, flag: @rtab}), do: {state, {:focus, :prev}}
  def handle(state, %{type: :key, key: :tab}), do: {state, {:focus, :next}}
  def handle(state, %{type: :key, key: :kdown}), do: {state, {:focus, :next}}
  def handle(state, %{type: :key, key: :kup}), do: {state, {:focus, :prev}}
  def handle(state, %{type: :key, key: :kright}), do: {state, {:focus, :next}}
  def handle(state, %{type: :key, key: :kleft}), do: {state, {:focus, :prev}}
  def handle(state, %{type: :key, key: :enter, flag: @renter}), do: retrigger(state)
  def handle(state, %{type: :key, key: :enter}), do: {state, {:focus, :next}}
  def handle(state, %{type: :key, key: ' '}), do: trigger(state)
  def handle(state, %{type: :mouse, action: :press}), do: trigger(state)
  def handle(state, _event), do: {state, nil}

  def render(state, canvas) do
    %{
      text: text,
      theme: theme,
      checked: checked,
      focused: focused,
      size: {cols, _},
      enabled: enabled
    } = state

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

    canvas = Canvas.move(canvas, 0, 0)
    canvas = Canvas.write(canvas, "[")
    canvas = Canvas.write(canvas, if(checked, do: "x", else: " "))
    canvas = Canvas.write(canvas, "]")
    text = String.pad_trailing(text, cols - 3)
    Canvas.write(canvas, text)
  end

  defp retrigger(%{on_change: on_change, checked: checked} = state) do
    {state, {:checked, checked, on_change.(checked)}}
  end

  defp trigger(%{on_change: on_change, checked: checked} = state) do
    checked = !checked
    state = Map.put(state, :checked, checked)
    {state, {:checked, checked, on_change.(checked)}}
  end

  defp check(state) do
    Check.assert_boolean(:focused, state.focused)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_gte(:findex, state.findex, -1)
    Check.assert_atom(:theme, state.theme)
    Check.assert_string(:text, state.text)
    Check.assert_boolean(:checked, state.checked)
    Check.assert_function(:on_change, state.on_change, 1)
    state
  end
end
