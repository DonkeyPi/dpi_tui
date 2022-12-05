defmodule Ash.Tui.Select do
  @behaviour Ash.Tui.Control
  use Ash.Tui.Const
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

    state = %{
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

    state = recalculate(state)
    check(state)
  end

  def nop({_index, _value}), do: nil

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_change: cb}) when not is_function(cb, 1), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def focused(%{focused: focused}), do: focused
  def focused(state, focused), do: %{state | focused: focused}
  def refocus(state, _), do: state
  def findex(%{findex: findex}), do: findex
  def shortcut(_), do: nil
  def children(_), do: []
  def children(state, _), do: state
  def modal(_), do: false

  def update(%{items: items} = state, props) do
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
    state = Control.merge(state, props)
    state = recalculate(state)
    check(state)
  end

  def handle(%{items: []} = state, %{type: :key}), do: {state, nil}
  def handle(%{items: []} = state, %{type: :mouse}), do: {state, nil}

  def handle(state, %{type: :key, key: :kdown}) do
    %{count: count, selected: selected} = state
    next = min(selected + 1, count - 1)
    trigger(state, next, selected)
  end

  def handle(state, %{type: :key, key: :kup}) do
    %{selected: selected} = state
    next = max(0, selected - 1)
    trigger(state, next, selected)
  end

  def handle(state, %{type: :key, key: :pdown}) do
    %{count: count, selected: selected, size: {_, rows}} = state
    next = min(selected + rows, count - 1)
    trigger(state, next, selected)
  end

  def handle(state, %{type: :key, key: :pup}) do
    %{selected: selected, size: {_, rows}} = state
    next = max(0, selected - rows)
    trigger(state, next, selected)
  end

  def handle(state, %{type: :key, key: :end}) do
    %{count: count, selected: selected} = state
    trigger(state, count - 1, selected)
  end

  def handle(state, %{type: :key, key: :home}) do
    %{selected: selected} = state
    trigger(state, 0, selected)
  end

  def handle(state, %{type: :mouse, action: :scroll, dir: :up}) do
    handle(state, %{type: :key, key: :kup})
  end

  def handle(state, %{type: :mouse, action: :scroll, dir: :down}) do
    handle(state, %{type: :key, key: :kdown})
  end

  def handle(state, %{type: :mouse, action: :press, y: my}) do
    %{count: count, selected: selected, offset: offset} = state
    next = my + offset
    next = if next >= count, do: selected, else: next
    trigger(state, next, selected)
  end

  def handle(state, %{type: :key, key: :tab, flag: @rtab}), do: {state, {:focus, :prev}}
  def handle(state, %{type: :key, key: :tab}), do: {state, {:focus, :next}}
  def handle(state, %{type: :key, key: :kright}), do: {state, {:focus, :next}}
  def handle(state, %{type: :key, key: :kleft}), do: {state, {:focus, :prev}}
  def handle(state, %{type: :key, key: :enter, flag: @renter}), do: {state, trigger(state)}
  def handle(state, %{type: :key, key: :enter}), do: {state, {:focus, :next}}
  def handle(state, _event), do: {state, nil}

  def render(state, canvas) do
    %{
      map: map,
      theme: theme,
      enabled: enabled,
      size: {cols, rows},
      focused: focused,
      selected: selected,
      offset: offset
    } = state

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
         } = state
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

    %{state | selected: selected, offset: offset}
  end

  defp trigger(state, next, selected) do
    state = %{state | selected: next}
    state = recalculate(state)

    case state.selected do
      ^selected -> {state, nil}
      _ -> {state, trigger(state)}
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

  defp check(state) do
    Check.assert_boolean(:focused, state.focused)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_gte(:findex, state.findex, -1)
    Check.assert_atom(:theme, state.theme)
    Check.assert_list(:items, state.items)
    Check.assert_integer(:selected, state.selected)
    Check.assert_map(:map, state.map)
    Check.assert_gte(:count, state.count, 0)
    Check.assert_gte(:offset, state.offset, 0)
    Check.assert_function(:on_change, state.on_change, 1)
    state
  end
end
