defmodule Ash.Tui.Panel do
  @behaviour Ash.Tui.Control
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Canvas
  alias Ash.Tui.Theme

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {0, 0})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    class = Map.get(opts, :class, nil)
    root = Map.get(opts, :root, false)

    model = %{
      focused: root,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      class: class,
      root: root,
      index: [],
      children: %{},
      focusables: %{},
      focus: nil
    }

    check(model)
  end

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focused(%{focused: focused}), do: focused
  def focused(model, focused), do: Map.put(model, :focused, focused)
  def refocus(model, dir), do: recalculate(model, dir)
  def findex(%{findex: findex}), do: findex
  def shortcut(_), do: nil
  def valid(_), do: true
  def modal(%{root: root}), do: root

  # Modals are ignored by focus calculator.
  def focusable(%{root: true}), do: false
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{findex: findex}) when findex < 0, do: false

  def focusable(%{focusables: focusables}) do
    Enum.any?(focusables, fn {_, focusable} -> focusable end)
  end

  def children(%{index: index, children: children}) do
    for id <- index, do: {id, children[id]}
  end

  def children(model, children) do
    {index, children, focusables} =
      for {id, child} <- children, reduce: {[], %{}, %{}} do
        {index, children, focusables} ->
          if id == nil, do: raise("Invalid child id: #{id}")
          if Map.has_key?(children, id), do: raise("Duplicated child id: #{id}")
          focused = momo_focused(child)
          focusable = momo_focusable(child)
          modal = momo_modal(child)

          # Do not undo auto focus for modals.
          child =
            case {focused, focusable, modal} do
              {true, false, false} -> momo_focused(child, false, :next)
              _ -> child
            end

          children = Map.put(children, id, child)
          focusables = Map.put(focusables, id, focusable)
          {[id | index], children, focusables}
      end

    model = Map.put(model, :focusables, focusables)
    model = Map.put(model, :children, children)
    model = Map.put(model, :index, index |> Enum.reverse())
    recalculate(model, :next)
  end

  def update(model, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:root, :children, :focus, :index, :focused])
    model = Control.merge(model, props)
    model = recalculate(model, :next)
    check(model)
  end

  # Handles: mouse, key, modal, and shortcut.

  # Modals have absolute positioning. Offset begins at modal.
  def handle(
        %{origin: {x, y}} = model,
        {:modal, [], %{type: :mouse, x: mx, y: my} = event}
      ) do
    handle(model, %{event | x: mx - x, y: my - y})
  end

  def handle(model, {:modal, [], event}), do: handle(model, event)

  def handle(model, {:modal, [id | tail], event}) do
    momo = model.children[id]
    {momo, event} = momo_handle(momo, {:modal, tail, event})
    model = put_child(model, id, momo)
    {model, event}
  end

  # Shortcuts restricted to focusables.
  def handle(model, {:shortcut, [id], {shortcut, action}}) do
    momo = model.children[id]

    if momo_focusable(momo) do
      event = {:shortcut, shortcut, action}
      {momo, event} = momo_handle(momo, event)
      {put_child(model, id, momo), event}
    else
      {model, nil}
    end
  end

  def handle(model, {:shortcut, [id | ids], event}) do
    momo = model.children[id]

    if momo_focusable(momo) do
      event = {:shortcut, ids, event}
      {momo, event} = momo_handle(momo, event)
      {put_child(model, id, momo), event}
    else
      {model, nil}
    end
  end

  # Prevent next handler from receiving a key event with nil focus.
  def handle(%{focus: nil} = model, %{type: :key}), do: {model, nil}

  def handle(%{focus: focus} = model, %{type: :key} = event) do
    momo = get_child(model, focus)
    {momo, event} = momo_handle(momo, event)
    child_event(model, momo, event)
  end

  # Controls get focused before receiving a mouse event
  # unless the root panel has no focusable children at all.

  # Prevent next handler from receiving a mouse event with nil focus.
  # This seems counter intuitive, but the root panel should always
  # have a focused child or the mouse event has no destination.
  def handle(%{focus: nil} = model, %{type: :mouse}), do: {model, nil}

  # Looks for the child containing the (x, y) event point. The child
  # becomes focused if not already then the event is handed to it.
  def handle(
        %{focus: focus, index: index, children: children} = model,
        %{type: :mouse, x: mx, y: my} = event
      ) do
    # top to bottom
    index = Enum.reverse(index)

    Enum.find_value(index, {model, nil}, fn id ->
      momo = Map.get(children, id)
      focusable = momo_focusable(momo)
      visible = momo_visible(momo)
      bounds = momo_bounds(momo)
      client = Control.toclient(bounds, mx, my)
      # Invisible modals are implicitly ignored.
      # Visible modals would ignore events because they are not focusabled.
      # Visible modals nested in visible modal would ignore events for same reason.
      #
      # This does not (should not) impact modals event handling.
      # The support for modals and nested modals depends on which
      # modal gets detected and cached by the driver.
      case {focusable, visible, client, focus == id} do
        {_, false, _, _} ->
          false

        {_, _, false, _} ->
          false

        {false, _, _, _} ->
          {model, nil}

        {_, _, {dx, dy}, true} ->
          event = %{event | x: dx, y: dy}
          {momo, event} = momo_handle(momo, event)
          child_event(model, momo, event)

        {_, _, {dx, dy}, _} ->
          model = unfocus(model)
          model = %{model | focus: id}
          momo = momo_focused(momo, true, :next)
          event = %{event | x: dx, y: dy}
          {momo, event} = momo_handle(momo, event)
          child_event(model, momo, event)
      end
    end)
  end

  def handle(model, _event), do: {model, nil}

  def render(%{index: index, children: children} = model, canvas, theme) do
    %{size: {cols, rows}} = model

    canvas = Canvas.fore(canvas, theme.(:fore, :normal))
    canvas = Canvas.back(canvas, theme.(:back, :normal))

    line = String.duplicate(" ", cols)

    canvas =
      for r <- 0..(rows - 1), reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          Canvas.write(canvas, line)
      end

    for id <- index, reduce: canvas do
      canvas ->
        canvas = Canvas.reset(canvas)
        momo = Map.get(children, id)
        momo_render(momo, canvas, id)
    end
  end

  # This is recursive. Both in setting and removing focus.
  # Assumes no child other than the pointed by the focus will
  # be ever focused. No attempt is made to unfocus every children.
  defp recalculate(model, dir) do
    %{
      visible: visible,
      enabled: enabled,
      focused: focused,
      findex: findex,
      focus: focus
    } = model

    expected = visible and enabled and focused and findex >= 0

    # Try to recover the current focus returning nil if not recoverable
    {model, focus} =
      case focus do
        nil ->
          {model, nil}

        _ ->
          case get_child(model, focus) do
            nil ->
              model = Map.put(model, :focus, nil)
              {model, nil}

            momo ->
              focused = momo_focused(momo)
              focusable = momo_focusable(momo)

              case {focusable and expected, focused} do
                {false, false} ->
                  model = Map.put(model, :focus, nil)
                  {model, nil}

                {false, true} ->
                  momo = momo_focused(momo, false, dir)
                  model = put_child(model, focus, momo)
                  model = Map.put(model, :focus, nil)
                  {model, nil}

                {true, false} ->
                  momo = momo_focused(momo, true, dir)
                  model = put_child(model, focus, momo)
                  {model, focus}

                {true, true} ->
                  {model, focus}
              end
          end
      end

    # Try to initialize focus if nil.
    case {expected, focus} do
      {true, nil} ->
        case focus_list(model, dir) do
          [] ->
            model

          [focus | _] ->
            momo = get_child(model, focus)
            momo = momo_focused(momo, true, dir)
            model = put_child(model, focus, momo)
            Map.put(model, :focus, focus)
        end

      _ ->
        model
    end
  end

  defp child_event(%{focus: focus, root: root} = model, momo, event) do
    case event do
      {:focus, dir} ->
        {first, next} = focus_next(model, focus, dir)

        # Critical to remove and reapply focused even
        # and specially when next equals current focus.
        next =
          case {root, first, next} do
            {true, ^focus, nil} -> focus
            {true, _, nil} -> first
            _ -> next
          end

        case next do
          nil ->
            {put_child(model, focus, momo), {:focus, dir}}

          _ ->
            momo = momo_focused(momo, false, dir)
            model = put_child(model, focus, momo)
            momo = get_child(model, next)
            momo = momo_focused(momo, true, dir)
            model = put_child(model, next, momo)
            {Map.put(model, :focus, next), nil}
        end

      nil ->
        {put_child(model, focus, momo), nil}

      _ ->
        {put_child(model, focus, momo), {focus, event}}
    end
  end

  defp focus_next(model, focus, dir) do
    index = focus_list(model, dir)

    case index do
      [] ->
        {nil, nil}

      [first | _] ->
        {next, _} =
          Enum.reduce_while(index, {nil, nil}, fn id, {_, prev} ->
            case {focus == id, focus == prev} do
              {true, _} -> {:cont, {nil, id}}
              {_, true} -> {:halt, {id, nil}}
              _ -> {:cont, {nil, nil}}
            end
          end)

        {first, next}
    end
  end

  defp focus_list(model, :prev) do
    index = focus_list(model, :next)
    Enum.reverse(index)
  end

  defp focus_list(model, :next) do
    %{index: index} = model
    index = Enum.filter(index, &child_focusable(model, &1))
    Enum.sort(index, &focus_compare(model, &1, &2))
  end

  defp focus_compare(model, id1, id2) do
    fi1 = child_findex(model, id1)
    fi2 = child_findex(model, id2)
    fi1 >= fi2
  end

  defp unfocus(%{focus: focus} = model) do
    momo = get_child(model, focus)
    momo = momo_focused(momo, false, :next)
    put_child(model, focus, momo)
  end

  defp get_child(model, id), do: get_in(model, [:children, id])
  defp put_child(model, id, child), do: put_in(model, [:children, id], child)
  defp child_focusable(model, id), do: momo_focusable(get_child(model, id))
  defp child_findex(model, id), do: momo_findex(get_child(model, id))
  defp momo_bounds({module, model}), do: module.bounds(model)
  defp momo_findex({module, model}), do: module.findex(model)
  defp momo_focusable({module, model}), do: module.focusable(model)
  defp momo_focused({module, model}), do: module.focused(model)
  defp momo_visible({module, model}), do: module.visible(model)
  defp momo_modal({module, model}), do: module.modal(model)

  # Modal or hidden panels are not rendered.
  defp momo_render({module, model}, canvas, id) do
    visible = module.visible(model)
    modal = module.modal(model)

    case {visible, modal} do
      {false, _} ->
        canvas

      {_, true} ->
        canvas

      _ ->
        theme = Theme.get(id, module, model)
        bounds = module.bounds(model)
        canvas = Canvas.push(canvas, bounds)
        canvas = module.render(model, canvas, theme)
        Canvas.pop(canvas)
    end
  end

  defp momo_focused({module, model}, focused, dir) do
    model = module.focused(model, focused)
    model = module.refocus(model, dir)
    {module, model}
  end

  defp momo_handle({module, model}, event) do
    {model, event} = module.handle(model, event)
    {{module, model}, event}
  end

  defp check(model) do
    Check.assert_boolean(:focused, model.focused)
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_boolean(:enabled, model.enabled)
    Check.assert_gte(:findex, model.findex, -1)
    Check.assert_boolean(:root, model.root)
    Check.assert_map(:children, model.children)
    Check.assert_list(:index, model.index)
    model
  end
end
