defmodule Ash.Tui.Driver do
  @behaviour Ash.React.Driver
  use Ash.Tui.Events
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
    put(:modal, nil)
    put(:module, nil)
    put(:model, nil)
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
        put(:modal, {ids, module, model})
      end
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
    modal = get(:modal)
    id = get(:id)

    event =
      case event do
        %{type: :key, action: action, key: key, flag: :none} when key in @shortcuts ->
          {:shortcut, key, action}

        _ ->
          event
      end

    event =
      case modal do
        nil -> event
        {id, _module, _model} -> {:modal, id, event}
      end

    # Events that trigger an on_XXX handler return
    # the handler return value nested in path tuples
    # like {:p0, {:c0, {:click, :nop}}}
    {model, _event} = module.handle(model, event)
    tree = Control.tree({module, model}, [id])
    put(:model, model)
    put(:tree, tree)
    :ok
  end

  def render(id, {module, model}) do
    cols = get(:cols)
    rows = get(:rows)
    modal = get(:modal)

    theme = Theme.get(id, module, model)

    canvas1 = Canvas.new(cols, rows)
    canvas2 = Canvas.new(cols, rows)
    canvas2 = module.render(model, canvas2, theme)

    canvas2 =
      case modal do
        nil ->
          canvas2

        {id, module, model} ->
          theme = Theme.get(id, module, model)
          bounds = module.bounds(model)
          canvas2 = Canvas.modal(canvas2)
          canvas2 = Canvas.push(canvas2, bounds)
          canvas2 = module.render(model, canvas2, theme)
          Canvas.pop(canvas2)
      end

    # FIXME pass canvas1 to optimize with diff
    data =
      encode(canvas1, canvas2, fn command, param ->
        Term.encode(command, param)
      end)

    :ok = Term.write("c#{data}")
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
