defmodule Ash.Tui.Radio do
  @behaviour Ash.Tui.Control
  use Ash.Tui.Events
  use Ash.Tui.Colors
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Radio
  alias Ash.Tui.Canvas

  # Size if not autocalculated from items because render and mouse
  # events are auto clipped making the issues evident for the user.
  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {0, 0})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    class = Map.get(opts, :class, nil)
    items = Map.get(opts, :items, [])
    selected = Map.get(opts, :selected, 0)
    on_change = Map.get(opts, :on_change, &Radio.nop/1)

    {count, map} = internals(items)

    model = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      class: class,
      items: items,
      selected: selected,
      count: count,
      map: map,
      on_change: on_change
    }

    model = recalculate(model)
    check(model)
  end

  def nop({index, value}), do: {:nop, {index, value}}

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

  def update(%{items: items} = model, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused, :count, :map])

    props =
      case props do
        %{items: ^items} ->
          props

        %{items: items} ->
          {count, map} = internals(items)
          props = Map.put(props, :map, map)
          props = Map.put(props, :count, count)
          props = Map.put_new(props, :selected, 0)
          %{props | items: items}

        _ ->
          props
      end

    props = Control.coalesce(props, :on_change, &Radio.nop/1)
    model = Control.merge(model, props)
    model = recalculate(model)
    check(model)
  end

  # Prevent next handlers from receiving a key event with no items.
  def handle(%{items: []} = model, %{type: :key}), do: {model, nil}
  # Prevent next handlers from receiving a mouse event with no items.
  def handle(%{items: []} = model, %{type: :mouse}), do: {model, nil}

  def handle(model, @ev_kp_kright) do
    %{count: count, selected: selected} = model
    next = min(selected + 1, count - 1)
    trigger(model, next, selected)
  end

  def handle(model, @ev_kp_kleft) do
    %{selected: selected} = model
    next = max(0, selected - 1)
    trigger(model, next, selected)
  end

  def handle(model, @ev_kp_end) do
    %{count: count, selected: selected} = model
    trigger(model, count - 1, selected)
  end

  def handle(model, @ev_kp_home) do
    %{selected: selected} = model
    trigger(model, 0, selected)
  end

  def handle(model, %{type: :mouse, action: :press, key: :bleft, x: mx}) do
    %{count: count, map: map, selected: selected} = model

    list = for i <- 0..(count - 1), do: {i, String.length("#{map[i]}")}

    list =
      for {i, l} <- list, reduce: [] do
        [] -> [{i, 0, l}]
        [{_, _, e} | _] = list -> [{i, e + 1, e + 1 + l} | list]
      end

    Enum.find_value(list, {model, nil}, fn {i, s, e} ->
      case mx >= s and mx < e do
        false -> false
        true -> trigger(model, i, selected)
      end
    end)
  end

  def handle(model, @ev_ms_up), do: handle(model, @ev_kp_kleft)
  def handle(model, @ev_ms_down), do: handle(model, @ev_kp_kright)
  def handle(model, @ev_kp_fprev), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_fnext), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kdown), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kup), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_trigger), do: {model, trigger(model)}
  def handle(model, @ev_kp_enter), do: {model, {:focus, :next}}
  def handle(model, _event), do: {model, nil}

  def render(model, canvas, theme) do
    %{
      map: map,
      count: count,
      selected: selected
    } = model

    {canvas, _} =
      for i <- 0..(count - 1), reduce: {canvas, 0} do
        {canvas, x} ->
          prefix =
            case i do
              0 -> ""
              _ -> " "
            end

          canvas =
            if i == selected do
              canvas = Canvas.color(canvas, :fore, theme.({:fore, :selected}))
              Canvas.color(canvas, :back, theme.({:back, :selected}))
            else
              canvas = Canvas.color(canvas, :fore, theme.({:fore, :default}))
              Canvas.color(canvas, :back, theme.({:back, :default}))
            end

          canvas = Canvas.move(canvas, x, 0)
          canvas = Canvas.write(canvas, prefix)

          item = Map.get(map, i)
          item = "#{item}"
          canvas = Canvas.write(canvas, item)
          len = String.length(prefix) + String.length(item)
          {canvas, x + len}
      end

    canvas
  end

  # -1 if empty or out of range
  defp recalculate(%{selected: selected, count: count} = model) do
    selected =
      case {count, selected < 0 or selected >= count} do
        {0, _} -> -1
        {_, true} -> -1
        _ -> selected
      end

    %{model | selected: selected}
  end

  defp trigger(model, next, selected) do
    model = %{model | selected: next}

    case model.selected do
      ^selected -> {model, nil}
      _ -> {model, trigger(model)}
    end
  end

  defp trigger(%{selected: selected, map: map, on_change: on_change}) do
    item = map[selected]
    resp = on_change.({selected, item})
    {:item, selected, item, resp}
  end

  defp internals(map) do
    for item <- map, reduce: {0, %{}} do
      {count, map} ->
        {count + 1, Map.put(map, count, item)}
    end
  end

  defp check(model) do
    Check.assert_boolean(:focused, model.focused)
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_boolean(:enabled, model.enabled)
    Check.assert_gte(:findex, model.findex, -1)
    Check.assert_list(:items, model.items)
    Check.assert_gte(:selected, model.selected, -1)
    Check.assert_map(:map, model.map)
    Check.assert_gte(:count, model.count, 0)
    Check.assert_function(:on_change, model.on_change, 1)
    model
  end
end
