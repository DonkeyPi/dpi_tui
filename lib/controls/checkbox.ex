defmodule Ash.Tui.Checkbox do
  @behaviour Ash.Tui.Control
  use Ash.Tui.Events
  use Ash.Tui.Colors
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Checkbox
  alias Ash.Tui.Canvas

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {String.length(text) + 3, 1})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    class = Map.get(opts, :class, nil)
    checked = Map.get(opts, :checked, false)
    on_change = Map.get(opts, :on_change, &Checkbox.nop/1)

    model = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      class: class,
      text: text,
      checked: checked,
      on_change: on_change
    }

    check(model)
  end

  def nop(value), do: {:nop, value}

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_change: cb}) when not is_function(cb, 1), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def focused(%{focused: focused}), do: focused
  def focused(model, focused), do: %{model | focused: focused}
  def refocus(model, _), do: model
  def findex(%{findex: findex}), do: findex
  def shortcut(_), do: nil
  def children(_), do: []
  def children(model, _), do: model
  def modal(_), do: false

  def update(model, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused])
    props = Control.coalesce(props, :on_change, &Checkbox.nop/1)
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
  def handle(model, @ev_kp_trigger), do: retrigger(model)
  def handle(model, @ev_kp_space), do: trigger(model)
  def handle(model, @ev_mp_left), do: trigger(model)
  def handle(model, _event), do: {model, nil}

  def render(model, canvas, theme) do
    %{
      text: text,
      checked: checked,
      size: {cols, rows}
    } = model

    canvas = Canvas.color(canvas, :fore, theme.({:fore, :normal}))
    canvas = Canvas.color(canvas, :back, theme.({:back, :normal}))

    line = String.duplicate(" ", cols)

    canvas =
      for r <- 0..(rows - 1), reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          Canvas.write(canvas, line)
      end

    canvas = Canvas.move(canvas, 0, 0)
    canvas = Canvas.write(canvas, "[")
    canvas = Canvas.write(canvas, if(checked, do: "X", else: " "))
    canvas = Canvas.write(canvas, "]")
    text = String.pad_trailing(text, cols - 3)
    Canvas.write(canvas, text)
  end

  defp retrigger(%{on_change: on_change, checked: checked} = model) do
    {model, {:checked, checked, on_change.(checked)}}
  end

  defp trigger(%{on_change: on_change, checked: checked} = model) do
    checked = !checked
    model = Map.put(model, :checked, checked)
    {model, {:checked, checked, on_change.(checked)}}
  end

  defp check(model) do
    Check.assert_boolean(:focused, model.focused)
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_boolean(:enabled, model.enabled)
    Check.assert_gte(:findex, model.findex, -1)
    Check.assert_string(:text, model.text)
    Check.assert_boolean(:checked, model.checked)
    Check.assert_function(:on_change, model.on_change, 1)
    model
  end
end
