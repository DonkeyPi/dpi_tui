defmodule Ash.Tui.Driver do
  @behaviour Ash.React.Driver
  alias Ash.Tui.Screen
  alias Ash.Tui.Canvas
  alias Ash.Tui.Control

  defp get(), do: Process.get(__MODULE__)
  defp put(state), do: Process.put(__MODULE__, state)

  def start(opts) do
    {screen, opts} = Keyword.pop!(opts, :screen)
    screen = Screen.start(screen, opts)
    opts = Screen.opts(screen)
    cols = Keyword.fetch!(opts, :cols)
    rows = Keyword.fetch!(opts, :rows)

    state = %{
      canvas: Canvas.new(cols, rows),
      screen: screen,
      module: nil,
      model: nil,
      cols: cols,
      rows: rows,
      tree: %{},
      id: nil
    }

    put(state)
    :ok
  end

  def opts(), do: Screen.opts(get().screen)

  # On root node it captures module, model, and id
  # and appends extra props [root: true].
  def update(ids, node) do
    state = get()
    {module, props, children} = node

    {root, id, props} =
      case ids do
        [id] -> {true, id, props ++ [root: true]}
        _ -> {false, nil, props}
      end

    model =
      case Map.get(state.tree, ids) do
        {^module, model} -> module.update(model, props)
        nil -> module.init(props)
      end

    model = module.children(model, children)

    if root do
      state = %{state | module: module, model: model, id: id}
      put(state)
    end

    {module, model}
  end

  def handles?({:event, _}), do: true
  def handles?(_msg), do: false

  # Uses module, model, and id
  # Generates model tree with root [id]
  def handle({:event, event}) do
    %{module: module, model: model, id: id} = get()
    # FIXME what is event for?
    # FIXME ensure event always returns nil
    {model, _event} = module.handle(model, event)
    # IO.inspect({:handle, _event})
    tree = Control.tree({module, model}, [id])
    put(%{get() | model: model, tree: tree})
    :ok
  end

  def render(_id, {module, model}) do
    state = get()
    %{screen: screen, cols: cols, rows: rows} = state

    canvas1 = Canvas.new(cols, rows)
    canvas2 = Canvas.new(cols, rows)
    canvas2 = module.render(model, canvas2)

    # FIXME pass canvas1 to optimize with diff
    data =
      encode(canvas1, canvas2, fn command, param ->
        Screen.encode(screen, command, param)
      end)

    :ok = Screen.write(screen, "#{data}")
    put(%{state | canvas: canvas2})
    :ok
  end

  defp encode(canvas1, canvas2, encoder) do
    {cursor1, _, _} = Canvas.get(canvas1, :cursor)
    {cursor2, _, _} = Canvas.get(canvas2, :cursor)
    diff = Canvas.diff(canvas1, canvas2)
    # do not hide cursor for empty or cursor only diffs
    # hide cursor before write or move and then restore
    diff =
      case diff do
        [] ->
          diff

        [{:c, _}] ->
          diff

        _ ->
          case {cursor1, cursor2} do
            {true, true} ->
              diff = [{:c, true} | diff]
              diff = :lists.reverse(diff)
              [{:c, false} | diff]

            {true, false} ->
              diff = :lists.reverse(diff)
              [{:c, false} | diff]

            _ ->
              :lists.reverse(diff)
          end
      end

    data = Canvas.encode(encoder, diff)
    IO.iodata_to_binary(data)
  end
end
