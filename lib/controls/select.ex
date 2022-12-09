defmodule Ash.Tui.Select do
  @behaviour Ash.Tui.Control
  use Ash.Tui.Events
  use Ash.Tui.Colors
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Select
  alias Ash.Tui.Canvas
  alias Ash.Tui.Theme

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {0, 0})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    theme = Map.get(opts, :theme, :default)
    items = Map.get(opts, :items, [])
    selected = Map.get(opts, :selected, 0)
    offset = Map.get(opts, :offset, 0)
    on_change = Map.get(opts, :on_change, &Select.nop/1)

    {count, map} = internals(items)

    model = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      theme: theme,
      findex: findex,
      items: items,
      selected: selected,
      count: count,
      map: map,
      offset: offset,
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
    props = Map.drop(props, [:focused, :count, :map, :offset])

    props =
      case props do
        %{items: ^items} ->
          props

        %{items: items} ->
          {count, map} = internals(items)
          props = Map.put(props, :map, map)
          props = Map.put(props, :count, count)
          props = Map.put(props, :offset, 0)
          props = Map.put_new(props, :selected, 0)
          %{props | items: items}

        _ ->
          props
      end

    props = Control.coalesce(props, :on_change, &Select.nop/1)
    model = Control.merge(model, props)
    model = recalculate(model)
    check(model)
  end

  # Prevent next handlers from receiving a key event with no items.
  def handle(%{items: []} = model, %{type: :key}), do: {model, nil}
  # Prevent next handlers from receiving a mouse event with no items.
  def handle(%{items: []} = model, %{type: :mouse}), do: {model, nil}

  def handle(model, @ev_kp_kdown) do
    %{count: count, selected: selected} = model
    next = min(selected + 1, count - 1)
    trigger(model, next, selected)
  end

  def handle(model, @ev_kp_kup) do
    %{selected: selected} = model
    next = max(0, selected - 1)
    trigger(model, next, selected)
  end

  def handle(model, @ev_kp_pdown) do
    %{count: count, selected: selected, size: {_, rows}} = model
    next = min(selected + rows, count - 1)
    trigger(model, next, selected)
  end

  def handle(model, @ev_kp_pup) do
    %{selected: selected, size: {_, rows}} = model
    next = max(0, selected - rows)
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

  def handle(model, %{type: :mouse, action: :press, key: :bleft, y: my}) do
    %{count: count, selected: selected, offset: offset} = model
    next = my + offset
    next = if next >= count, do: selected, else: next
    trigger(model, next, selected)
  end

  def handle(model, @ev_ms_up), do: handle(model, @ev_kp_kup)
  def handle(model, @ev_ms_down), do: handle(model, @ev_kp_kdown)
  def handle(model, @ev_kp_fprev), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_fnext), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kright), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kleft), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_enter), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_trigger), do: {model, trigger(model)}
  def handle(model, _event), do: {model, nil}

  def render(model, canvas) do
    %{
      map: map,
      theme: theme,
      enabled: enabled,
      size: {cols, rows},
      focused: focused,
      selected: selected,
      offset: offset
    } = model

    theme = Theme.get(theme)

    for i <- 0..(rows - 1), reduce: canvas do
      canvas ->
        canvas = Canvas.move(canvas, 0, i)
        canvas = Canvas.clear(canvas, :colors)

        canvas =
          case {enabled, focused, i == selected - offset} do
            {false, _, _} ->
              canvas = Canvas.color(canvas, :fore, theme.fore_disabled)
              Canvas.color(canvas, :back, theme.back_disabled)

            {true, true, true} ->
              canvas = Canvas.color(canvas, :fore, theme.fore_focused)
              Canvas.color(canvas, :back, theme.back_focused)

            {true, false, true} ->
              canvas = Canvas.color(canvas, :fore, theme.fore_selected)
              Canvas.color(canvas, :back, theme.back_selected)

            _ ->
              canvas = Canvas.color(canvas, :fore, theme.fore_editable)
              Canvas.color(canvas, :back, theme.back_editable)
          end

        item = Map.get(map, i + offset, "")
        item = "#{item}"
        item = String.pad_trailing(item, cols)
        Canvas.write(canvas, item)
    end
  end

  # -1 if empty or out of range (selected)
  # offset is recalculated to make selected visible
  # to support :kdown | :kup | :pdown | :pup events
  defp recalculate(
         %{
           selected: selected,
           size: {_, rows},
           count: count,
           offset: offset
         } = model
       ) do
    outofrange = selected < 0 or selected >= count
    offmin = if selected >= rows, do: selected + 1 - rows, else: 0

    {selected, offset} =
      cond do
        count == 0 -> {-1, 0}
        outofrange -> {-1, 0}
        rows == 0 -> {-1, 0}
        offset < offmin -> {selected, offmin}
        offset > selected -> {selected, selected}
        true -> {selected, offset}
      end

    %{model | selected: selected, offset: offset}
  end

  defp trigger(model, next, selected) do
    model = %{model | selected: next}
    model = recalculate(model)

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
    Check.assert_atom(:theme, model.theme)
    Check.assert_list(:items, model.items)
    Check.assert_integer(:selected, model.selected)
    Check.assert_map(:map, model.map)
    Check.assert_gte(:count, model.count, 0)
    Check.assert_gte(:offset, model.offset, 0)
    Check.assert_function(:on_change, model.on_change, 1)
    model
  end
end
