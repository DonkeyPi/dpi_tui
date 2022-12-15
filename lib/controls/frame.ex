defmodule Ash.Tui.Frame do
  @behaviour Ash.Tui.Control
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Canvas

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    origin = Map.get(opts, :origin, {0, 0})
    text = Map.get(opts, :text, "")
    size = Map.get(opts, :size, {String.length(text) + 2, 2})
    visible = Map.get(opts, :visible, true)
    class = Map.get(opts, :class, nil)
    border = Map.get(opts, :border, :single)

    model = %{
      origin: origin,
      size: size,
      visible: visible,
      class: class,
      border: border,
      text: text
    }

    check(model)
  end

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(_), do: false
  def focused(_), do: false
  def focused(model, _), do: model
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
      border: border,
      size: {cols, rows},
      text: text
    } = model

    canvas = Canvas.color(canvas, :fore, theme.({:fore, :normal}))
    canvas = Canvas.color(canvas, :back, theme.({:back, :normal}))

    top = [
      border_char(border, :top_left),
      text |> String.slice(0, max(0, cols - 2)),
      String.duplicate(border_char(border, :horizontal), max(0, cols - 2 - String.length(text))),
      border_char(border, :top_right)
    ]

    middle = [
      border_char(border, :vertical),
      String.duplicate(" ", cols - 2),
      border_char(border, :vertical)
    ]

    bottom = [
      border_char(border, :bottom_left),
      String.duplicate(border_char(border, :horizontal), cols - 2),
      border_char(border, :bottom_right)
    ]

    canvas =
      for r <- 1..(rows - 2), reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          Canvas.write(canvas, middle)
      end

    canvas = Canvas.move(canvas, 0, 0)
    canvas = Canvas.write(canvas, top)
    canvas = Canvas.move(canvas, 0, rows - 1)
    Canvas.write(canvas, bottom)
  end

  defp check(model) do
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_in_list(:border, model.border, [:single, :double, :round])
    Check.assert_string(:text, model.text)
    model
  end

  # https://en.wikipedia.org/wiki/Box-drawing_character
  defp border_char(border, elem) do
    case border do
      :single ->
        case elem do
          :top_left -> "┌"
          :top_right -> "┐"
          :bottom_left -> "└"
          :bottom_right -> "┘"
          :horizontal -> "─"
          :vertical -> "│"
        end

      :double ->
        case elem do
          :top_left -> "╔"
          :top_right -> "╗"
          :bottom_left -> "╚"
          :bottom_right -> "╝"
          :horizontal -> "═"
          :vertical -> "║"
        end

      :round ->
        case elem do
          :top_left -> "╭"
          :top_right -> "╮"
          :bottom_left -> "╰"
          :bottom_right -> "╯"
          :horizontal -> "─"
          :vertical -> "│"
        end
    end
  end
end
