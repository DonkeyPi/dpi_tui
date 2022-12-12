defmodule Ash.Tui.Label do
  @behaviour Ash.Tui.Control
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Canvas

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {String.length(text), 1})
    visible = Map.get(opts, :visible, true)
    class = Map.get(opts, :class, nil)

    model = %{
      origin: origin,
      size: size,
      visible: visible,
      class: class,
      text: text
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
  def modal(_), do: false

  def update(model, props) do
    props = Enum.into(props, %{})
    model = Control.merge(model, props)
    check(model)
  end

  def handle(model, _event), do: {model, nil}

  def render(model, canvas, theme) do
    %{
      text: text,
      size: {cols, rows}
    } = model

    canvas = Canvas.color(canvas, :fore, theme.({:fore, :normal}))
    canvas = Canvas.color(canvas, :back, theme.({:back, :normal}))

    line = String.duplicate(" ", cols)

    canvas =
      for r <- 0..(rows - 1), reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          Canvas.write(canvas, line)
      end

    # center vertically
    offy = div(rows - 1, 2)
    text = String.pad_trailing(text, rows)
    canvas = Canvas.move(canvas, 0, offy)
    Canvas.write(canvas, text)
  end

  defp check(model) do
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_string(:text, model.text)
    model
  end
end
