defmodule Dpi.Tui.Select do
  @behaviour Dpi.Tui.Control
  use Dpi.Tui.Events
  use Dpi.Tui.Colors
  alias Dpi.Tui.Control
  alias Dpi.Tui.Check
  alias Dpi.Tui.Select
  alias Dpi.Tui.Canvas

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    origin = Map.get(opts, :origin, {0, 0})
    items = Map.get(opts, :items, [])

    stringer = Map.get(opts, :stringer, &Select.stringer/1)

    {cols, rows} =
      for item <- items, reduce: {0, 0} do
        {cols, rows} -> {max(cols, String.length(stringer.(item))), rows + 1}
      end

    size = Map.get(opts, :size, {cols, rows})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    class = Map.get(opts, :class, nil)
    selected = if items == [], do: -1, else: 0
    selected = Map.get(opts, :selected, selected)
    offset = Map.get(opts, :offset, 0)
    on_action = Map.get(opts, :on_action, &Select.nop/1)
    on_change = Map.get(opts, :on_change, &Select.nop/1)

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
      offset: offset,
      stringer: stringer,
      on_action: on_action,
      on_change: on_change
    }

    initial = {selected, Map.get(map, selected)}
    model = recalculate(model)
    %{selected: selected} = model
    calculated = {selected, Map.get(map, selected)}
    if calculated != initial, do: on_change.(calculated)
    check(model)
  end

  def stringer(value) when is_binary(value), do: value
  def stringer(value), do: "#{value}"
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
  def valid(_), do: true
  def modal(_), do: false

  def update(%{items: items, selected: selected, map: map} = model, props) do
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
    previous = {selected, Map.get(map, selected)}
    %{on_change: on_change, selected: selected, map: map} = model
    calculated = {selected, Map.get(map, selected)}
    if calculated != previous, do: on_change.(calculated)
    check(model)
  end

  # handle focus even on empty items
  def handle(model, @ev_ms_up), do: handle(model, @ev_kp_kup)
  def handle(model, @ev_ms_down), do: handle(model, @ev_kp_kdown)
  def handle(model, @ev_ms_pup), do: handle(model, @ev_kp_pup)
  def handle(model, @ev_ms_pdown), do: handle(model, @ev_kp_pdown)
  def handle(model, @ev_kp_fprev), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_fprev2), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_fnext), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kright), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kleft), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_enter), do: {model, {:focus, :next}}

  # Prevent next handlers from receiving a key event with no items.
  def handle(%{items: []} = model, %{type: :key}), do: {model, nil}
  # Prevent next handlers from receiving a mouse event with no items.
  def handle(%{items: []} = model, %{type: :mouse}), do: {model, nil}

  def handle(model, @ev_kp_space), do: {model, retrigger(model)}
  def handle(model, @ev_kp_enter_ctrl), do: {model, retrigger(model)}

  def handle(model, %{type: :mouse, action: :press, key: :bleft, y: my, flag: :control}) do
    %{count: count, selected: selected, offset: offset} = model
    next = my + offset
    next = if next >= count, do: selected, else: next

    case next == selected do
      true -> {model, retrigger(model)}
      _ -> {model, nil}
    end
  end

  def handle(model, %{type: :mouse, action: :press2, key: :bleft, y: my, flag: :none}) do
    %{count: count, selected: selected, offset: offset} = model
    next = my + offset
    next = if next >= count, do: selected, else: next

    case next == selected do
      true -> {model, retrigger(model)}
      _ -> {model, nil}
    end
  end

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

  def handle(model, %{type: :mouse, action: :press, key: :bleft, y: my, flag: :none}) do
    %{count: count, selected: selected, offset: offset} = model
    next = my + offset
    next = if next >= count, do: selected, else: next
    trigger(model, next, selected)
  end

  def handle(model, _event), do: {model, nil}

  def render(model, canvas, theme) do
    %{
      map: map,
      stringer: stringer,
      size: {cols, rows},
      selected: selected,
      offset: offset
    } = model

    for i <- 0..(rows - 1), reduce: canvas do
      canvas ->
        oi = i + offset

        canvas =
          if oi == selected do
            canvas = Canvas.fore(canvas, theme.(:fore, :selected))
            Canvas.back(canvas, theme.(:back, :selected))
          else
            canvas = Canvas.fore(canvas, theme.(:fore, :normal))
            Canvas.back(canvas, theme.(:back, :normal))
          end

        canvas = Canvas.move(canvas, 0, i)

        item =
          case Map.has_key?(map, oi) do
            true -> Map.get(map, oi) |> stringer.()
            _ -> ""
          end

        item = String.slice(item, 0, cols)
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
    item = Map.get(map, selected)
    resp = on_change.({selected, item})
    {:item, selected, item, resp}
  end

  defp retrigger(%{selected: selected, map: map, on_action: on_action}) do
    item = Map.get(map, selected)
    resp = on_action.({selected, item})
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
    Check.assert_integer(:selected, model.selected)
    Check.assert_map(:map, model.map)
    Check.assert_gte(:count, model.count, 0)
    Check.assert_gte(:offset, model.offset, 0)
    Check.assert_function(:stringer, model.stringer, 1)
    Check.assert_function(:on_action, model.on_action, 1)
    Check.assert_function(:on_change, model.on_change, 1)
    model
  end
end
