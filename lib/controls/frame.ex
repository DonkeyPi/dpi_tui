defmodule Ash.Tui.Frame do
  @behaviour Ash.Tui.Control
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Canvas
  alias Ash.Tui.Theme

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {0, 0})
    visible = Map.get(opts, :visible, true)
    theme = Map.get(opts, :theme, :default)
    theme = Theme.get(theme)
    bracket = Map.get(opts, :bracket, false)
    style = Map.get(opts, :style, :single)
    text = Map.get(opts, :text, "")
    back = Map.get(opts, :back, theme.back_readonly)
    fore = Map.get(opts, :fore, theme.fore_readonly)

    model = %{
      origin: origin,
      size: size,
      visible: visible,
      bracket: bracket,
      style: style,
      text: text,
      back: back,
      fore: fore
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
  def modal(_), do: false

  def update(model, props) do
    props = Enum.into(props, %{})
    model = Control.merge(model, props)
    check(model)
  end

  def handle(model, _event), do: {model, nil}

  def render(model, canvas) do
    %{
      bracket: bracket,
      style: style,
      size: {cols, rows},
      text: text,
      back: back,
      fore: fore
    } = model

    canvas = Canvas.clear(canvas, :colors)
    canvas = Canvas.color(canvas, :back, back)
    canvas = Canvas.color(canvas, :fore, fore)
    last = rows - 1

    canvas =
      for r <- 0..last, reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          horizontal = border_char(style, :horizontal)
          vertical = border_char(style, :vertical)

          border =
            case r do
              0 ->
                [
                  border_char(style, :top_left),
                  String.duplicate(horizontal, cols - 2),
                  border_char(style, :top_right)
                ]

              ^last ->
                [
                  border_char(style, :bottom_left),
                  String.duplicate(horizontal, cols - 2),
                  border_char(style, :bottom_right)
                ]

              _ ->
                [vertical, String.duplicate(" ", cols - 2), vertical]
            end

          Canvas.write(canvas, border)
      end

    canvas = Canvas.move(canvas, 1, 0)

    text =
      case bracket do
        true -> "[#{text}]"
        false -> " #{text} "
      end

    Canvas.write(canvas, text)
  end

  defp check(model) do
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_boolean(:bracket, model.bracket)
    Check.assert_in_list(:style, model.style, [:single, :double])
    Check.assert_string(:text, model.text)
    Check.assert_color(:back, model.back)
    Check.assert_color(:fore, model.fore)
    model
  end

  # https://en.wikipedia.org/wiki/Box-drawing_character
  defp border_char(style, elem) do
    case style do
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

      _ ->
        " "
    end
  end
end
