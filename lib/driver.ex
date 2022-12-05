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

  def update(ids, node) do
    %{tree: tree} = get()
    {module, props, children} = node

    model =
      case Map.get(tree, ids) do
        {^module, model} -> module.update(model, props)
        nil -> module.init(props)
      end

    {module, module.children(model, children)}
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
    IO.inspect({:handle, _event})
    tree = Control.tree({module, model}, [id])
    put(%{get() | model: model, tree: tree})
    :ok
  end

  # Captures module, model, and id
  def render(id, {module, model}) do
    put(%{get() | module: module, model: model, id: id})
    %{screen: screen, cols: cols, rows: rows} = get()

    canvas1 = Canvas.new(cols, rows)
    canvas2 = Canvas.new(cols, rows)
    canvas2 = module.render(model, canvas2)

    # FIXME pass canvas1 to optimize with diff
    data =
      encode(canvas1, canvas2, fn command, param ->
        Screen.encode(screen, command, param)
      end)

    :ok = Screen.write(screen, "#{data}")
    %{get() | canvas: canvas2}
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
