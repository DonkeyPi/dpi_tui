defmodule Ash.Tui.Canvas do
  use Ash.Tui.Colors
  use Bitwise

  @char 32
  @fore @white
  @back @black
  @dimmed @black2
  @factor {1, 0, 0}
  @cursor {false, 0, 0}

  def new(cols, rows, opts \\ []) do
    fore = Keyword.get(opts, :fore, @fore)
    back = Keyword.get(opts, :back, @back)
    font = Keyword.get(opts, :font, 0)

    %{
      x: 0,
      y: 0,
      data: %{},
      cols: cols,
      rows: rows,
      cell: {@char, fore, back, font, @factor},
      cursor: @cursor,
      font: font,
      fore: fore,
      back: back,
      opaque: true,
      factor: @factor,
      clip: {0, 0, cols, rows},
      clips: []
    }
  end

  def modal(canvas, opts \\ []) do
    canvas = reset(canvas)
    fg = Keyword.get(opts, :fore, @dimmed)
    bg = Keyword.get(opts, :back, @back)
    data = for {key, {d, _, _, ff, fc}} <- canvas.data, do: {key, {d, fg, bg, ff, fc}}
    %{canvas | data: Enum.into(data, %{}), cursor: @cursor}
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
          # always grows, assumes positive xy
          x = ax + ix
          y = ay + iy
          # always shrinks, assumes positive wh
          w = min(iw, aw - ix)
          h = min(ih, ah - iy)
          {x, y, w, h}
      end

    %{canvas | clip: clip}
  end

  def reset(%{clip: {cx, cy, _, _}, cell: {_, fore, back, font, factor}} = canvas) do
    %{canvas | font: font, fore: fore, back: back, factor: factor, opaque: true, x: cx, y: cy}
  end

  def move(%{clip: {cx, cy, _, _}} = canvas, x, y) do
    %{canvas | x: cx + x, y: cy + y}
  end

  def cursor(%{clip: {cx, cy, _, _}} = canvas, x, y) do
    %{canvas | cursor: {true, cx + x, cy + y}}
  end

  def font(canvas, font) when font in 0..0xFF, do: %{canvas | font: font}

  def back(canvas, nil), do: %{canvas | opaque: false}

  def back(canvas, {r, g, b}) when r in 0..0xFF and g in 0..0xFF and b in 0..0xFF,
    do: %{canvas | back: r <<< 16 ||| g <<< 8 ||| b}

  def back(canvas, color) when color in 0..0xFFFFFF,
    do: %{canvas | back: color, opaque: true}

  def fore(canvas, color) when color in 0..0xFFFFFF, do: %{canvas | fore: color}

  def fore(canvas, {r, g, b}) when r in 0..0xFF and g in 0..0xFF and b in 0..0xFF,
    do: %{canvas | fore: r <<< 16 ||| g <<< 8 ||| b}

  def factor(canvas, factor, fx, fy) when factor in 1..16 and fx in 0..15 and fy in 0..15,
    do: %{canvas | factor: {factor, fx, fy}}

  # writes a single line clipping excess to avoid terminal wrapping
  def write(canvas, chardata) do
    %{
      x: x,
      y: y,
      data: data,
      font: ff,
      fore: fg,
      back: bg,
      opaque: opaque,
      cell: cell,
      factor: fc,
      clip: {cx, cy, cw, ch}
    } = canvas

    cx2 = cx + cw
    cy2 = cy + ch

    if y < cy or y >= cy2 do
      canvas
    else
      {data, x} =
        chardata
        |> IO.chardata_to_string()
        |> String.to_charlist()
        |> Enum.reduce({data, x}, fn c, {data, x} ->
          if x < cx or x >= cx2 do
            # don't write, but walk the path
            {data, x + 1}
          else
            # use current background if not opaque
            bg = if opaque, do: bg, else: Map.get(data, {x, y}, cell) |> elem(2)
            data = Map.put(data, {x, y}, {c, fg, bg, ff, fc})
            {data, x + 1}
          end
        end)

      %{canvas | data: data, x: x}
    end
  end

  def diff(canvas1, canvas2) do
    %{
      x: x1,
      y: y1,
      cell: cel1,
      data: data1,
      rows: rows,
      cols: cols,
      font: ff1,
      back: bg1,
      fore: fg1,
      factor: fc1,
      cursor: {c1, cx1, cy1}
    } = canvas1

    %{
      x: x2,
      y: y2,
      font: ff2,
      back: bg2,
      fore: fg2,
      cell: cel2,
      data: data2,
      rows: ^rows,
      cols: ^cols,
      factor: fc2,
      cursor: {c2, cx2, cy2}
    } = canvas2

    # when the cursor is enabled it becomes the new end point
    {x1, y1} =
      case c1 do
        true -> {cx1, cy1}
        false -> {x1, y1}
      end

    {list, f, b, x, y, ff, fc} =
      for row <- 0..(rows - 1), col <- 0..(cols - 1), reduce: {[], fg1, bg1, x1, y1, ff1, fc1} do
        {list, f, b, x, y, ff, fc} ->
          cel1 = Map.get(data1, {col, row}, cel1)
          cel2 = Map.get(data2, {col, row}, cel2)

          case cel2 == cel1 do
            true ->
              {list, f, b, x, y, ff, fc}

            false ->
              {d2, fg2, bg2, ff2, fc2} = cel2

              list =
                case x == col do
                  true -> list
                  false -> [{:x, col} | list]
                end

              list =
                case y == row do
                  true -> list
                  false -> [{:y, row} | list]
                end

              list =
                case f == fg2 do
                  true -> list
                  false -> [{:f, fg2} | list]
                end

              list =
                case b == bg2 do
                  true -> list
                  false -> [{:b, bg2} | list]
                end

              list =
                case ff == ff2 do
                  true -> list
                  false -> [{:n, ff2} | list]
                end

              list =
                case fc == fc2 do
                  true -> list
                  false -> [{:e, fc2} | list]
                end

              # To update fore and back the char needs to
              # be written even if it did not changed.
              # Encoding should maximize readability.
              list =
                case list do
                  [{:d, {[^d2], n}} | tail] -> [{:d, {[d2], n + 1}} | tail]
                  [{:d, [^d2]} | tail] -> [{:d, {[d2], 2}} | tail]
                  [{:d, [^d2 | dd]} | tail] -> [{:d, {[d2], 2}}, {:d, dd} | tail]
                  [{:d, dd} | tail] when is_list(dd) -> [{:d, [d2 | dd]} | tail]
                  _ -> [{:d, [d2]} | list]
                end

              # term does not wrap x around
              {list, fg2, bg2, col + 1, row, ff2, fc2}
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
        true -> list
        false -> [{:x, x2} | list]
      end

    list =
      case y == y2 do
        true -> list
        false -> [{:y, y2} | list]
      end

    list =
      case f == fg2 do
        true -> list
        false -> [{:f, fg2} | list]
      end

    list =
      case b == bg2 do
        true -> list
        false -> [{:b, bg2} | list]
      end

    list =
      case ff == ff2 do
        true -> list
        false -> [{:n, ff2} | list]
      end

    list =
      case fc == fc2 do
        true -> list
        false -> [{:e, fc2} | list]
      end

    list =
      for item <- list do
        case item do
          {:d, {d, n}} -> {:d, {d, n}}
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

  defp encode(encoder, list, [{:n, n} | tail]) do
    d = encoder.(:font, n)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:e, e} | tail]) do
    d = encoder.(:factor, e)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:c, true} | tail]) do
    d = encoder.(:show, nil)
    encode(encoder, [d | list], tail)
  end

  defp encode(encoder, list, [{:c, false} | tail]) do
    d = encoder.(:hide, nil)
    encode(encoder, [d | list], tail)
  end
end
