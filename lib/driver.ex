defmodule Ash.Tui.Driver do
  @behaviour Ash.React.Driver
  use Ash.Tui.Events
  alias Ash.Tui.Term
  alias Ash.Tui.Canvas
  alias Ash.Tui.Control
  alias Ash.Tui.Theme

  defp get(key, value \\ nil), do: Process.get({__MODULE__, key}, value)
  defp put(key, value), do: Process.put({__MODULE__, key}, value)
  defp delete(key), do: Process.delete({__MODULE__, key})

  def start(opts) do
    {term, opts} = Keyword.pop!(opts, :term)
    :ok = Term.start(term, opts)
    opts = Term.opts()
    cols = Keyword.fetch!(opts, :cols)
    rows = Keyword.fetch!(opts, :rows)
    put(:canvas, Canvas.new(cols, rows))
    put(:shortcuts, %{})
    put(:module, nil)
    put(:model, nil)
    put(:modal, nil)
    put(:cols, cols)
    put(:rows, rows)
    put(:tree, %{})
    put(:ids, [])
    put(:id, nil)
    :ok
  end

  def opts(), do: Term.opts()

  def push(id) do
    ids = get(:ids)

    if ids == [] do
      put(:shortcuts, %{})
      put(:modal, nil)
    end

    put(:ids, [id | ids])
    :ok
  end

  def pop() do
    [_ | tail] = get(:ids)
    put(:ids, tail)
    :ok
  end

  # On root node it captures module, model, and id
  # and appends extra props [root: true].
  def update(ids, {module, props, children}) do
    tree = get(:tree)

    {root, id, props} =
      case ids do
        [id] -> {true, id, props ++ [root: true]}
        _ -> {false, nil, props}
      end

    model =
      case Map.get(tree, ids) do
        {^module, model} -> module.update(model, props)
        nil -> module.init(props)
      end

    model = module.children(model, children)

    shortcut = module.shortcut(model)

    if shortcut != nil do
      [_ | ids] = Enum.reverse(ids)
      shortcuts = get(:shortcuts)

      shortcuts =
        case Map.get(shortcuts, shortcut) do
          nil -> Map.put(shortcuts, shortcut, [ids])
          curr -> Map.put(shortcuts, shortcut, [ids | curr])
        end

      put(:shortcuts, shortcuts)
    end

    if root do
      # not having an up-to-date tree means inits are replaced by
      # updates above and state is being lost or not reset.
      # A timer only app would only and always call inits
      # because the tree is never initialized.
      # Both tree updates are needed, here and in handle.
      put(:tree, Control.tree({module, model}, [id]))
      put(:module, module)
      put(:model, model)
      put(:id, id)
    else
      modal = module.modal(model)
      visible = module.visible(model)

      if modal and visible do
        [_ | ids] = Enum.reverse(ids)

        case get(:modal) do
          nil -> :ok
          {id2, _, _} -> raise "Duplicated modal #{inspect(ids)} and #{inspect(id2)}"
        end

        put(:modal, {ids, module, model})
      end
    end

    {module, model}
  end

  # Full refresh.
  def handle(%{type: :sys, key: :print}) do
    delete(:canvas)
    data = Term.encode(:clear, nil)
    :ok = Term.write(data)
  end

  # Uses module, model, and id.
  # Generates model tree with root [id].
  def handle(event) do
    module = get(:module)
    model = get(:model)
    modal = get(:modal)
    id = get(:id)

    # Process shortcuts synchronously accumulating module updates.
    # No direct model changes expected on shortcut handlers.
    # Model 'changes' accumulated for completeness sake.
    shortcuts = get(:shortcuts)

    # This updated model is lost if event nils below as happens
    # for mouse outside root client area. Safe at this time.
    model =
      with %{type: :key, action: action, key: key, flag: flag} <- event do
        for ids <- Map.get(shortcuts, {key, flag}, []), reduce: model do
          model ->
            event =
              case modal do
                nil ->
                  {:shortcut, ids, {{key, flag}, action}}

                {mid, _, _} ->
                  case Enum.split(ids, length(mid)) do
                    {^mid, tail} ->
                      event = {:shortcut, tail, {{key, flag}, action}}
                      {:modal, mid, event}

                    _ ->
                      nil
                  end
              end

            momo_handle(module, model, event)
        end
      else
        _ -> model
      end

    # Coordinates are translated on destination for modals.
    # Momo needed below to clip the rendering region.
    # Do not handle events directly to modal or its
    # model would need to be updated to its parent on the
    # main tree to avoid impacting state handling.
    event =
      case modal do
        nil -> event
        {mid, _, _} -> {:modal, mid, event}
      end

    # Offset coordinates for root panel.
    event =
      case event do
        %{type: :mouse, x: x, y: y} ->
          bounds = module.bounds(model)

          case Control.toclient(bounds, x, y) do
            false -> nil
            {x, y} -> %{event | x: x, y: y}
          end

        _ ->
          event
      end

    model = momo_handle(module, model, event)
    put(:tree, Control.tree({module, model}, [id]))
    put(:model, model)

    :ok
  end

  def render(id, {module, model}) do
    cols = get(:cols)
    rows = get(:rows)
    modal = get(:modal)

    theme = Theme.get(id, module, model)
    bounds = module.bounds(model)
    canvas = Canvas.new(cols, rows)
    canvas2 = Canvas.push(canvas, bounds)
    canvas2 = module.render(model, canvas2, theme)
    canvas2 = Canvas.pop(canvas2)

    canvas2 =
      case modal do
        nil ->
          canvas2

        {[id | _], module, model} ->
          theme = Theme.get(id, module, model)
          bounds = module.bounds(model)
          canvas2 = Canvas.modal(canvas2)
          canvas2 = Canvas.push(canvas2, bounds)
          canvas2 = module.render(model, canvas2, theme)
          Canvas.pop(canvas2)
      end

    canvas1 = get(:canvas, canvas)
    put(:canvas, canvas2)

    encoder = fn cmd, param ->
      Term.encode(cmd, param)
    end

    diff = Canvas.diff(canvas1, canvas2)
    data = Canvas.encode(encoder, diff)
    :ok = Term.write(data)
  end

  defp momo_handle(_module, model, nil), do: model

  defp momo_handle(module, model, event) do
    # Events that trigger an on_event handler return
    # value nested in tuples path like below:
    # {:p0, {:c0, {:click, :nop}}}
    {model, _event} = module.handle(model, event)
    model
  end
end
