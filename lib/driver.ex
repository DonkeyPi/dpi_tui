defmodule Ash.Tui.Driver do
  @behaviour Ash.React.Driver
  alias Ash.Tui.Term
  alias Ash.Tui.Canvas
  alias Ash.Tui.Control
  alias Ash.Tui.Theme

  defp get(key), do: Process.get({__MODULE__, key})
  defp put(key, data), do: Process.put({__MODULE__, key}, data)

  def start(opts) do
    {term, opts} = Keyword.pop!(opts, :term)
    :ok = Term.start(term, opts)
    opts = Term.opts()
    cols = Keyword.fetch!(opts, :cols)
    rows = Keyword.fetch!(opts, :rows)
    put(:canvas, Canvas.new(cols, rows))
    put(:module, nil)
    put(:model, nil)
    put(:cols, cols)
    put(:rows, rows)
    put(:tree, %{})
    put(:id, nil)
    :ok
  end

  def opts(), do: Term.opts()

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
    end

    {module, model}
  end

  def handles?({:event, _}), do: true
  def handles?(_msg), do: false

  # Uses module, model, and id
  # Generates model tree with root [id]
  def handle({:event, event}) do
    module = get(:module)
    model = get(:model)
    id = get(:id)
    # FIXME what is event for?
    # FIXME ensure event always returns nil
    {model, _event} = module.handle(model, event)
    # IO.inspect({:handle, _event})
    tree = Control.tree({module, model}, [id])
    put(:model, model)
    put(:tree, tree)
    :ok
  end

  def render(id, {module, model}) do
    cols = get(:cols)
    rows = get(:rows)

    theme = Theme.get(id, module, model)

    canvas1 = Canvas.new(cols, rows)
    canvas2 = Canvas.new(cols, rows)
    canvas2 = module.render(model, canvas2, theme)

    # FIXME pass canvas1 to optimize with diff
    data =
      encode(canvas1, canvas2, fn command, param ->
        Term.encode(command, param)
      end)

    :ok = Term.write("#{data}")
    put(:canvas, canvas2)
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
