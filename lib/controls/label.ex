defmodule Ash.Tui.Label do
  @behaviour Ash.Tui.Control
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Canvas

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    scale = Map.get(opts, :scale, 1)
    size = Map.get(opts, :size, {String.length(text) * scale, scale})
    visible = Map.get(opts, :visible, true)
    class = Map.get(opts, :class, nil)
    align = Map.get(opts, :align, :left)
    font = Map.get(opts, :font, 0)

    model = %{
      origin: origin,
      size: size,
      visible: visible,
      class: class,
      text: text,
      align: align,
      font: font,
      scale: scale
    }

    check(model)
  end

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(_), do: false
  def focused(model, _), do: model
  def focused(_), do: false
  def refocus(model, _), do: model
  def findex(_), do: -1
  def shortcut(_), do: nil
  def children(_), do: []
  def children(model, _), do: model
  def valid(_), do: true
  def modal(_), do: false

  def update(model, props) do
    props = Enum.into(props, %{})
    model = Control.merge(model, props)
    check(model)
  end

  def handle(model, _event), do: {model, nil}

  def render(model, canvas, theme) do
    %{
      font: font,
      text: text,
      align: align,
      scale: scale,
      size: {cols, rows}
    } = model

    canvas = Canvas.font(canvas, font)
    canvas = Canvas.fore(canvas, theme.(:fore, :normal))
    canvas = Canvas.back(canvas, theme.(:back, :normal))

    line = String.duplicate(" ", cols)

    canvas =
      for r <- 0..(rows - 1), reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          Canvas.write(canvas, line)
      end

    # center vertically
    offy = div(rows - scale, 2)

    offx =
      case align do
        :left -> 0
        :right -> cols - scale * String.length(text)
        :center -> div(cols - scale * String.length(text), 2)
      end

    chars = String.codepoints(text) |> Enum.with_index()

    for {c, i} <- chars, x <- 0..(scale - 1), y <- 0..(scale - 1), reduce: canvas do
      canvas ->
        # IO.inspect({i, c, x, y})
        canvas = Canvas.scale(canvas, scale, x, y)
        x = offx + i * scale + x
        y = offy + y
        canvas = Canvas.move(canvas, x, y)
        Canvas.write(canvas, c)
    end
  end

  defp check(model) do
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_string(:text, model.text)
    Check.assert_in_list(:align, model.align, [:left, :center, :right])
    Check.assert_in_range(:scale, model.scale, 1..16)
    Check.assert_in_range(:font, model.font, 0..0xFF)
    model
  end
end
