defmodule Ash.Tui.Canvas do
  use Ash.Tui.Const

  @cell {' ', @white, @black}

  def new(cols, rows) do
    %{
      x: 0,
      y: 0,
      data: %{},
      cols: cols,
      rows: rows,
      cursor: {false, 0, 0},
      fore: @white,
      back: @black,
      clip: {0, 0, cols, rows},
      clips: []
    }
  end

  def modal(canvas) do
    %{cols: cols, rows: rows} = canvas
    %{data: data} = canvas
    canvas = new(cols, rows)
    data = for {key, {d, _, _}} <- data, do: {key, {d, @bblack, @black}}
    data = Enum.into(data, %{})
    %{canvas | data: data}
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

  def get(%{cols: cols, rows: rows}, :size) do
    {cols, rows}
  end

  def get(%{cursor: cursor}, :cursor) do
    cursor
  end

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

  # writes a single line clipping excess to avoid terminal wrapping
  def write(canvas, chardata) do
    %{
      x: x,
      y: y,
      data: data,
      fore: fg,
      back: bg,
      clip: {cx, cy, cw, ch}
    } = canvas

    mx = cx + cw
    my = cy + ch

    {data, x, y} =
      chardata
      |> IO.chardata_to_string()
      |> String.to_charlist()
      |> Enum.reduce_while({data, x, y}, fn c, {data, x, y} ->
        case x < cx || y < cy || x >= mx || y >= my do
          true ->
            {:halt, {data, x, y}}

          false ->
            data = Map.put(data, {x, y}, {c, fg, bg})
            {:cont, {data, x + 1, y}}
        end
      end)

    %{canvas | data: data, x: x, y: y}
  end

  def diff(canvas1, canvas2) do
    %{
      data: data1,
      rows: rows,
      cols: cols,
      cursor: {cursor1, x1, y1},
      back: b1,
      fore: f1
    } = canvas1

    %{
      data: data2,
      rows: ^rows,
      cols: ^cols
    } = canvas2

    {list, f, b, x, y} =
      for row <- 0..(rows - 1), col <- 0..(cols - 1), reduce: {[], f1, b1, x1, y1} do
        {list, f0, b0, x, y} ->
          cel1 = Map.get(data1, {col, row}, @cell)
          cel2 = Map.get(data2, {col, row}, @cell)

          case cel2 == cel1 do
            true ->
              {list, f0, b0, x, y}

            false ->
              {c2, f2, b2} = cel2

              list =
                case {x, y} == {col, row} do
                  true ->
                    list

                  false ->
                    [{:m, col, row} | list]
                end

              list =
                case b0 == b2 do
                  true -> list
                  false -> [{:b, b2} | list]
                end

              list =
                case f0 == f2 do
                  true -> list
                  false -> [{:f, f2} | list]
                end

              # to update styles write c2 even if same to c1
              list =
                case list do
                  [{:d, d} | tail] -> [{:d, [c2 | d]} | tail]
                  _ -> [{:d, [c2]} | list]
                end

              row = row + div(col + 1, cols)
              col = rem(col + 1, cols)
              {list, f2, b2, col, row}
          end
      end

    # restore canvas2 styles and cursor
    %{
      cursor: {cursor2, x2, y2},
      back: b2,
      fore: f2
    } = canvas2

    list =
      case b == b2 do
        true -> list
        false -> [{:b, b2} | list]
      end

    list =
      case f == f2 do
        true -> list
        false -> [{:f, f2} | list]
      end

    list =
      case {x, y} == {x2, y2} do
        true -> list
        false -> [{:m, x2, y2} | list]
      end

    list =
      case cursor1 == cursor2 do
        true -> list
        false -> [{:c, cursor2} | list]
      end

    list
  end

  def encode(encoder, list) when is_list(list) do
    list = encode(encoder, [], list)
    :lists.reverse(list)
  end

  defp encode(_, list, []), do: list

  defp encode(encoder, list, [{:m, x, y} | tail]) do
    d = encoder.(:move, {x, y})
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:d, d} | tail]) do
    d = :lists.reverse(d)
    d = IO.chardata_to_string(d)
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

  defp encode(encoder, list, [{:c, c} | tail]) do
    d =
      case c do
        true -> encoder.(:show, nil)
        false -> encoder.(:hide, nil)
      end

    encode(encoder, [d | list], tail)
  end
end
