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

  defp color(key, value, opts) do
    <<
      r::binary-size(2),
      g::binary-size(2),
      b::binary-size(2)
    >> = Keyword.get(opts, key, value)

    r = String.to_integer(r, 16)
    g = String.to_integer(g, 16)
    b = String.to_integer(b, 16)
    {r, g, b}
  end

  def start(opts) do
    {term, opts} = Keyword.pop!(opts, :term)
    :ok = Term.start(term, opts)
    opts = Term.opts()
    cols = Keyword.fetch!(opts, :cols)
    rows = Keyword.fetch!(opts, :rows)
    put(:back, color(:bgcolor, "000000", opts))
    put(:fore, color(:fgcolor, "FFFFFF", opts))
    put(:canvas, Canvas.new(cols, rows))
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

    if root do
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
          {id2, _, _} -> raise "Duplicated modal #{ids} and #{id2}"
        end

        put(:modal, {ids, module, model})
      end
    end

    {module, model}
  end

  # full refresh
  def handle(%{type: :sys, key: :print}) do
    data = Term.encode(:clear, nil)
    :ok = Term.write(data)
    delete(:canvas)
    :ok
  end

  # Uses module, model, and id.
  # Generates model tree with root [id].
  def handle(event) do
    module = get(:module)
    model = get(:model)
    modal = get(:modal)
    id = get(:id)

    # Process shortcuts async.
    with %{type: :key, action: action, key: key, flag: flag} <- event,
         true <- Map.has_key?(@shortcutm, {key, flag}) do
      send(self(), {:event, %{type: :shortcut, shortcut: {key, flag}, action: action}})
    end

    # Coordinates are translated on destination for modals.
    # Momo needed below to clip the rendering region.
    # Do not handle events directly to modal or its
    # model would need to be updated to its parent on the
    # main tree to avoid impacting state handling.
    event =
      case modal do
        nil -> event
        {id, _module, _model} -> {:modal, id, event}
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

    if event != nil do
      # Events that trigger an on_event handler return
      # value nested in tuples path like below:
      # {:p0, {:c0, {:click, :nop}}}
      {model, _event} = module.handle(model, event)
      tree = Control.tree({module, model}, [id])
      put(:model, model)
      put(:tree, tree)
    end

    :ok
  end

  def render(id, {module, model}) do
    cols = get(:cols)
    rows = get(:rows)
    modal = get(:modal)

    theme = Theme.get(id, module, model)

    opts = [bg: get(:back), fg: get(:fore)]
    canvas2 = Canvas.new(cols, rows, opts)
    bounds = module.bounds(model)
    canvas2 = Canvas.push(canvas2, bounds)
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

    canvas1 = Canvas.new(cols, rows, opts)
    canvas1 = get(:canvas, canvas1)
    put(:canvas, canvas2)

    encoder = fn command, param ->
      Term.encode(command, param)
    end

    diff = Canvas.diff(canvas1, canvas2)
    data = Canvas.encode(encoder, diff)
    :ok = Term.write(data)
  end
end
