defmodule Ash.Tui.Canvas do
  use Ash.Tui.Colors
  use Bitwise

  def new(cols, rows, opts \\ []) do
    fg = Keyword.get(opts, :fg, @white)
    bg = Keyword.get(opts, :bg, @black)

    %{
      x: 0,
      y: 0,
      data: %{},
      cols: cols,
      rows: rows,
      cell: {' ', fg, bg, 0},
      cursor: {false, 0, 0},
      fore: fg,
      back: bg,
      factor: {1, 0, 0},
      clip: {0, 0, cols, rows},
      clips: []
    }
  end

  def modal(canvas, opts \\ []) do
    fg = Keyword.get(opts, :fg, @black2)
    bg = Keyword.get(opts, :bg, @black)
    data = for {key, {d, _, _, fe}} <- canvas.data, do: {key, {d, fg, bg, fe}}
    data = Enum.into(data, %{})
    %{canvas | data: data, cursor: {false, 0, 0}}
  end

  def push(%{clips: clips} = canvas, bounds) do
    canvas = %{canvas | clips: [bounds | clips]}
    update_clip(canvas)
  end

  def pop(%{clips: [_ | tail]} = canvas) do
    canvas = %{canvas | clips: tail}
    update_clip(canvas)
  end

  defp update_clip(%{cols: cols, rows: rows, clips: clips} = canvas) do
    clip = {0, 0, cols, rows}

    clip =
      for {ix, iy, iw, ih} <- Enum.reverse(clips), reduce: clip do
        {ax, ay, aw, ah} ->
          w = min(iw, aw - ix)
          h = min(ih, ah - iy)
          {ax + ix, ay + iy, w, h}
      end

    %{canvas | clip: clip}
  end

  def get(%{cols: cols, rows: rows}, :size), do: {cols, rows}
  def get(%{cell: cell}, :cell), do: cell
  def get(%{cursor: cursor}, :cursor), do: cursor

  def clear(canvas, :colors) do
    %{canvas | fore: @white, back: @black}
  end

  def move(%{clip: {cx, cy, _, _}} = canvas, x, y) do
    %{canvas | x: cx + x, y: cy + y}
  end

  def cursor(%{clip: {cx, cy, _, _}} = canvas, x, y) do
    %{canvas | cursor: {true, cx + x, cy + y}}
  end

  def color(canvas, :fore, color) do
    %{canvas | fore: color}
  end

  def color(canvas, :back, color) do
    %{canvas | back: color}
  end

  def factor(canvas, factor, x, y) do
    %{canvas | factor: {factor, x, y}}
  end

  # writes a single line clipping excess to avoid terminal wrapping
  def write(canvas, chardata) do
    %{
      x: x,
      y: y,
      data: data,
      fore: fg,
      back: bg,
      factor: fe,
      clip: {cx, cy, cw, ch}
    } = canvas

    mx = cx + cw
    my = cy + ch

    if y < cy or y >= my do
      canvas
    else
      {data, x} =
        chardata
        |> IO.chardata_to_string()
        |> String.to_charlist()
        |> Enum.reduce_while({data, x}, fn c, {data, x} ->
          case x < cx or x >= mx do
            true ->
              # don't write, but walk the path
              {:cont, {data, x + 1}}

            _ ->
              data = Map.put(data, {x, y}, {c, fg, bg, fe})
              {:cont, {data, x + 1}}
          end
        end)

      %{canvas | data: data, x: x}
    end
  end

  def diff(canvas1, canvas2) do
    %{
      x: x1,
      y: y1,
      cell: cell1,
      data: data1,
      rows: rows,
      cols: cols,
      back: b1,
      fore: f1,
      factor: e1,
      cursor: {c1, cx1, cy1}
    } = canvas1

    %{
      x: x2,
      y: y2,
      back: b2,
      fore: f2,
      cell: cell2,
      data: data2,
      rows: ^rows,
      cols: ^cols,
      factor: e2,
      cursor: {c2, cx2, cy2}
    } = canvas2

    # when the cursor is enabled it becomes the new end point
    {x1, y1} =
      case c1 do
        true -> {cx1, cy1}
        false -> {x1, y1}
      end

    {list, f, b, x, y, e} =
      for row <- 0..(rows - 1), col <- 0..(cols - 1), reduce: {[], f1, b1, x1, y1, e1} do
        {list, f, b, x, y, e} ->
          cel1 = Map.get(data1, {col, row}, cell1)
          cel2 = Map.get(data2, {col, row}, cell2)

          case cel2 == cel1 do
            true ->
              {list, f, b, x, y, e}

            false ->
              {d2, f2, b2, e2} = cel2

              list =
                case x == col do
                  true ->
                    list

                  false ->
                    [{:x, col} | list]
                end

              list =
                case y == row do
                  true ->
                    list

                  false ->
                    [{:y, row} | list]
                end

              list =
                case f == f2 do
                  true -> list
                  false -> [{:f, f2} | list]
                end

              list =
                case b == b2 do
                  true -> list
                  false -> [{:b, b2} | list]
                end

              list =
                case e == e2 do
                  true -> list
                  false -> [{:e, e2} | list]
                end

              # to update fore and back the char needs to
              # be written even if it did not changed
              list =
                case list do
                  [{:d, dd} | tail] -> [{:d, [d2 | dd]} | tail]
                  _ -> [{:d, [d2]} | list]
                end

              # term does not wrap x around
              {list, f2, b2, col + 1, row, e2}
          end
      end

    # when the cursor is enabled it becomes the new end point
    {list, x2, y2} =
      case {c1 == c2, c2} do
        {true, true} -> {list, cx2, cy2}
        {true, false} -> {list, x2, y2}
        {false, true} -> {[{:c, c2} | list], cx2, cy2}
        {false, false} -> {[{:c, c2} | list], x2, y2}
      end

    list =
      case x == x2 do
        true ->
          list

        false ->
          [{:x, x2} | list]
      end

    list =
      case y == y2 do
        true ->
          list

        false ->
          [{:y, y2} | list]
      end

    list =
      case f == f2 do
        true -> list
        false -> [{:f, f2} | list]
      end

    list =
      case b == b2 do
        true -> list
        false -> [{:b, b2} | list]
      end

    list =
      case e == e2 do
        true -> list
        false -> [{:e, e2} | list]
      end

    list =
      for item <- list do
        case item do
          {:d, d} -> {:d, Enum.reverse(d)}
          other -> other
        end
      end

    list |> Enum.reverse()
  end

  def encode(encoder, list) when is_list(list) do
    list = encode(encoder, [], list)
    :lists.reverse(list)
  end

  defp encode(_, list, []), do: list

  defp encode(encoder, list, [{:x, x} | tail]) do
    d = encoder.(:x, x)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:y, y} | tail]) do
    d = encoder.(:y, y)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:d, d} | tail]) do
    d = encoder.(:text, d)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:b, b} | tail]) do
    d = encoder.(:back, b)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:f, f} | tail]) do
    d = encoder.(:fore, f)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:e, e} | tail]) do
    d = encoder.(:factor, e)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:c, c} | tail]) do
    d =
      case c do
        true -> encoder.(:show, nil)
        false -> encoder.(:hide, nil)
      end

    encode(encoder, [d | list], tail)
  end
end
