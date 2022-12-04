defmodule Ash.Tui.Input do
  @behaviour Ash.Tui.Control
  use Ash.Tui.Const
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Input
  alias Ash.Tui.Canvas
  alias Ash.Tui.Theme

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {String.length(text), 1})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    theme = Map.get(opts, :theme, :default)
    password = Map.get(opts, :password, false)
    cursor = Map.get(opts, :cursor, String.length(text))
    on_change = Map.get(opts, :on_change, &Input.nop/1)

    state = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      theme: theme,
      password: password,
      text: text,
      cursor: cursor,
      on_change: on_change
    }

    check(state)
  end

  def nop(_value), do: nil

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_change: cb}) when not is_function(cb, 1), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def focused(%{focused: focused}), do: focused
  def focused(state, focused), do: %{state | focused: focused}
  def refocus(state, _), do: state
  def findex(%{findex: findex}), do: findex
  def shortcut(_), do: nil
  def children(_), do: []
  def children(state, _), do: state
  def modal(_), do: false

  def update(%{text: text} = state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused, :cursor])

    props =
      case props do
        %{text: ^text} ->
          props

        %{text: text} ->
          cursor = String.length(text)
          props = Map.put(props, :text, text)
          props = Map.put(props, :cursor, cursor)
          %{props | text: text}

        _ ->
          props
      end

    props = Control.coalesce(props, :on_change, &Input.nop/1)
    state = Control.merge(state, props)
    check(state)
  end

  def handle(state, %{type: :key, key: :tab, flag: @rtab}), do: {state, {:focus, :prev}}
  def handle(state, %{type: :key, key: :tab}), do: {state, {:focus, :next}}
  def handle(state, %{type: :key, key: :kdown}), do: {state, {:focus, :next}}
  def handle(state, %{type: :key, key: :kup}), do: {state, {:focus, :prev}}
  def handle(state, %{type: :key, key: :enter, flag: @renter}), do: {state, trigger(state)}
  def handle(state, %{type: :key, key: :enter}), do: {state, {:focus, :next}}

  def handle(%{cursor: cursor} = state, %{type: :key, key: :kleft}) do
    cursor = if cursor > 0, do: cursor - 1, else: cursor
    state = %{state | cursor: cursor}
    {state, nil}
  end

  def handle(%{cursor: cursor, text: text} = state, %{type: :key, key: :kright}) do
    count = String.length(text)
    cursor = if cursor < count, do: cursor + 1, else: cursor
    state = %{state | cursor: cursor}
    {state, nil}
  end

  def handle(state, %{type: :key, key: :home}) do
    state = %{state | cursor: 0}
    {state, nil}
  end

  def handle(%{text: text} = state, %{type: :key, key: :end}) do
    count = String.length(text)
    state = %{state | cursor: count}
    {state, nil}
  end

  def handle(%{cursor: cursor, text: text} = state, %{type: :key, key: :backspace}) do
    case cursor do
      0 ->
        {state, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        {prefix, _} = String.split_at(prefix, cursor - 1)
        cursor = cursor - 1
        text = "#{prefix}#{suffix}"
        state = %{state | text: text, cursor: cursor}
        {state, trigger(state)}
    end
  end

  def handle(%{cursor: cursor, text: text} = state, %{type: :key, key: :delete}) do
    count = String.length(text)

    case cursor do
      ^count ->
        {state, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        suffix = String.slice(suffix, 1..String.length(suffix))
        text = "#{prefix}#{suffix}"
        state = %{state | text: text}
        {state, trigger(state)}
    end
  end

  def handle(state, %{type: :key, key: data}) when is_list(data) do
    %{cursor: cursor, text: text, size: {cols, _}} = state
    count = String.length(text)

    case count do
      ^cols ->
        {state, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        text = "#{prefix}#{data}#{suffix}"
        state = %{state | text: text, cursor: cursor + 1}
        {state, trigger(state)}
    end
  end

  def handle(%{text: text} = state, %{type: :mouse, action: :press, x: mx}) do
    cursor = min(mx, String.length(text))
    state = %{state | cursor: cursor}
    {state, nil}
  end

  def handle(state, _event), do: {state, nil}

  def render(state, canvas) do
    %{
      focused: focused,
      theme: theme,
      cursor: cursor,
      enabled: enabled,
      password: password,
      size: {cols, _},
      text: text
    } = state

    theme = Theme.get(theme)
    canvas = Canvas.clear(canvas, :colors)
    empty = String.length(text) == 0
    dotted = empty && !focused && enabled

    canvas =
      case {enabled, focused} do
        {false, _} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_disabled)
          Canvas.color(canvas, :back, theme.back_disabled)

        {true, true} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_focused)
          Canvas.color(canvas, :back, theme.back_focused)

        _ ->
          canvas = Canvas.color(canvas, :fore, theme.fore_editable)
          Canvas.color(canvas, :back, theme.back_editable)
      end

    text =
      case {password, dotted} do
        {_, true} -> String.duplicate("_", cols)
        {true, _} -> String.duplicate("*", String.length(text))
        _ -> text
      end

    text = String.pad_trailing(text, cols)
    canvas = Canvas.move(canvas, 0, 0)
    canvas = Canvas.write(canvas, text)

    case {focused, enabled, cursor < cols} do
      {true, true, true} ->
        Canvas.cursor(canvas, cursor, 0)

      _ ->
        canvas
    end
  end

  defp trigger(%{on_change: on_change, text: text}) do
    resp = on_change.(text)
    {:text, text, resp}
  end

  defp check(state) do
    Check.assert_boolean(:focused, state.focused)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_gte(:findex, state.findex, -1)
    Check.assert_atom(:theme, state.theme)
    Check.assert_boolean(:password, state.password)
    Check.assert_string(:text, state.text)
    Check.assert_gte(:cursor, state.cursor, 0)
    Check.assert_function(:on_change, state.on_change, 1)
    state
  end
end
