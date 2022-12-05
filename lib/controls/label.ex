defmodule Ash.Tui.Label do
  @behaviour Ash.Tui.Control
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Canvas
  alias Ash.Tui.Theme

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {String.length(text), 1})
    visible = Map.get(opts, :visible, true)
    theme = Map.get(opts, :theme, :default)
    theme = Theme.get(theme)
    back = Map.get(opts, :back, theme.back_readonly)
    fore = Map.get(opts, :fore, theme.fore_readonly)

    state = %{
      origin: origin,
      size: size,
      visible: visible,
      text: text,
      back: back,
      fore: fore
    }

    check(state)
  end

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(_), do: false
  def focused(state, _), do: state
  def focused(_), do: false
  def refocus(state, _), do: state
  def findex(_), do: -1
  def shortcut(_), do: nil
  def children(_), do: []
  def children(state, _), do: state
  def modal(_), do: false

  def update(state, props) do
    props = Enum.into(props, %{})
    state = Control.merge(state, props)
    check(state)
  end

  def handle(state, _event), do: {state, nil}

  def render(state, canvas) do
    %{
      text: text,
      size: {cols, rows},
      back: back,
      fore: fore
    } = state

    canvas = Canvas.color(canvas, :back, back)
    canvas = Canvas.color(canvas, :fore, fore)

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

  defp check(state) do
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_string(:text, state.text)
    Check.assert_color(:back, state.back)
    Check.assert_color(:fore, state.fore)
    state
  end
end
