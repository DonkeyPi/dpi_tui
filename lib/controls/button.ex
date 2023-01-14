defmodule Dpi.Tui.Button do
  @behaviour Dpi.Tui.Control
  use Dpi.Tui.Events
  use Dpi.Tui.Colors
  alias Dpi.Tui.Control
  alias Dpi.Tui.Check
  alias Dpi.Tui.Button
  alias Dpi.Tui.Frame
  alias Dpi.Tui.Canvas
  alias Dpi.Tui.Label

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    scale = Map.get(opts, :scale, 1)
    border = Map.get(opts, :border, nil)
    margin = if border == nil, do: 0, else: 2
    size = Map.get(opts, :size, {String.length(text) * scale + margin, scale + margin})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    class = Map.get(opts, :class, nil)
    align = Map.get(opts, :align, :center)
    shortcut = Map.get(opts, :shortcut, nil)
    on_click = Map.get(opts, :on_click, &Button.nop/0)

    model = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      class: class,
      text: text,
      align: align,
      scale: scale,
      border: border,
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
  def valid(_), do: true
  def modal(_), do: false

  def update(model, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused])
    props = Control.coalesce(props, :on_click, &Button.nop/0)
    model = Control.merge(model, props)
    check(model)
  end

  def handle(model, @ev_kp_fprev), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_fprev2), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_fnext), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kdown), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kright), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kleft), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_kup), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_enter), do: trigger(model)
  def handle(model, @ev_kp_trigger), do: trigger(model)
  def handle(model, @ev_kp_space), do: trigger(model)
  def handle(model, @ev_mp_left), do: trigger(model)

  def handle(
        %{shortcut: shortcut} = model,
        {:shortcut, shortcut, :press}
      ),
      do: trigger(model)

  def handle(model, _event), do: {model, nil}

  def render(model, canvas, theme) do
    %{
      text: text,
      scale: scale,
      align: align,
      border: border,
      size: {cols, rows}
    } = model

    if border == nil do
      Label.render(
        %{size: {cols, rows}, text: text, scale: scale, font: 0, align: align},
        canvas,
        theme
      )
    else
      canvas = Frame.render(%{size: {cols, rows}, text: "", border: border}, canvas, theme)
      canvas = Canvas.push(canvas, {1, 1, cols - 2, rows - 2})

      Label.render(
        %{size: {cols - 2, rows - 2}, text: text, scale: scale, font: 0, align: :center},
        canvas,
        theme
      )
    end
  end

  # Panel prevents delivery of events to non focusables.
  # Shortcuts are also restricted to focusables by panel.
  defp trigger(%{enabled: false} = model), do: {model, nil}

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
    Check.assert_string(:text, model.text)
    Check.assert_in_range(:scale, model.scale, 1..16)
    Check.assert_in_list(:align, model.align, [:center, :left, :right])
    Check.assert_in_list(:border, model.border, [nil, :single, :double, :round])
    Check.assert_function(:on_click, model.on_click, 0)
    model
  end
end
