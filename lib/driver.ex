defmodule Ash.Tui.Driver do
  @behaviour Ash.React.Driver
  alias Ash.Tui.Screen
  alias Ash.Tui.Canvas
  alias Ash.Tui.Control

  def start(opts) do
    {screen, opts} = Keyword.pop!(opts, :screen)
    screen = Screen.start(screen, opts)
    opts = Screen.opts(screen)
    cols = Keyword.fetch!(opts, :cols)
    rows = Keyword.fetch!(opts, :rows)

    %{
      screen: screen,
      canvas: Canvas.new(cols, rows),
      cols: cols,
      rows: rows,
      dom: nil
    }
  end

  def opts(%{screen: screen}), do: Screen.opts(screen)
  def tree(%{dom: {id, momo, _}}), do: Control.tree(momo, [id])

  def handles?(_state, {:event, _}), do: true
  def handles?(_state, _msg), do: false

  def handle(%{dom: _dom}, {:event, _event}) do
    :ok
  end

  def render(
        %{screen: screen, cols: cols, rows: rows} = state,
        {_, momo, _} = dom
      ) do
    {module, model} = momo
    canvas1 = Canvas.new(cols, rows)
    canvas2 = Canvas.new(cols, rows)
    canvas2 = module.render(model, canvas2)

    # FIXME pass canvas1 to optimize with diff
    data =
      encode(canvas1, canvas2, fn command, param ->
        Screen.encode(screen, command, param)
      end)

    :ok = Screen.write(screen, "#{data}")
    %{state | canvas: canvas2, dom: dom}
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
