defmodule Ash.Tui.Input do
  @behaviour Ash.Tui.Control
  use Ash.Tui.Events
  use Ash.Tui.Colors
  alias Ash.Tui.Control
  alias Ash.Tui.Check
  alias Ash.Tui.Input
  alias Ash.Tui.Canvas

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    text = Map.get(opts, :text, "")
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {String.length(text), 1})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    class = Map.get(opts, :class, nil)
    password = Map.get(opts, :password, false)
    cursor = Map.get(opts, :cursor, String.length(text))
    on_change = Map.get(opts, :on_change, &Input.nop/1)
    validate = Map.get(opts, :validate, &Input.validate/1)

    model = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      class: class,
      password: password,
      text: text,
      cursor: cursor,
      on_change: on_change,
      validate: validate
    }

    check(model)
  end

  def nop(value), do: {:nop, value}
  def validate(_), do: true

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_change: cb}) when not is_function(cb, 1), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def focused(%{focused: focused}), do: focused
  def focused(model, focused), do: %{model | focused: focused}
  def valid(%{validate: validate, text: text}), do: validate.(text)
  def refocus(model, _), do: model
  def findex(%{findex: findex}), do: findex
  def shortcut(_), do: nil
  def children(_), do: []
  def children(model, _), do: model
  def modal(_), do: false

  def update(%{text: text} = model, props) do
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
    model = Control.merge(model, props)
    check(model)
  end

  def handle(model, @ev_kp_fprev), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_fnext), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kdown), do: {model, {:focus, :next}}
  def handle(model, @ev_kp_kup), do: {model, {:focus, :prev}}
  def handle(model, @ev_kp_trigger), do: {model, trigger(model)}
  def handle(model, @ev_kp_enter), do: {model, {:focus, :next}}

  def handle(%{cursor: cursor} = model, @ev_kp_kleft) do
    cursor = if cursor > 0, do: cursor - 1, else: cursor
    model = %{model | cursor: cursor}
    {model, nil}
  end

  def handle(%{cursor: cursor, text: text} = model, @ev_kp_kright) do
    count = String.length(text)
    cursor = if cursor < count, do: cursor + 1, else: cursor
    model = %{model | cursor: cursor}
    {model, nil}
  end

  def handle(model, @ev_kp_home) do
    model = %{model | cursor: 0}
    {model, nil}
  end

  def handle(%{text: text} = model, @ev_kp_end) do
    count = String.length(text)
    model = %{model | cursor: count}
    {model, nil}
  end

  def handle(%{cursor: cursor, text: text} = model, @ev_kp_backspace) do
    case cursor do
      0 ->
        {model, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        cursor = cursor - 1
        {prefix, _} = String.split_at(prefix, cursor)
        text = "#{prefix}#{suffix}"
        model = %{model | text: text, cursor: cursor}
        {model, trigger(model)}
    end
  end

  def handle(%{cursor: cursor, text: text} = model, @ev_kp_delete) do
    count = String.length(text)

    case cursor do
      ^count ->
        {model, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        suffix = String.slice(suffix, 1..String.length(suffix))
        text = "#{prefix}#{suffix}"
        model = %{model | text: text}
        {model, trigger(model)}
    end
  end

  # allow shift + key
  def handle(model, %{type: :key, action: :press, key: data, flag: :shift} = msg)
      when is_list(data) do
    handle(model, %{msg | flag: :none})
  end

  def handle(model, %{type: :key, action: :press, key: data, flag: :none}) when is_list(data) do
    %{cursor: cursor, text: text, size: {cols, _}} = model
    count = String.length(text)

    case count do
      ^cols ->
        {model, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        len = String.length("#{data}")
        text = "#{prefix}#{data}#{suffix}"

        case String.length(text) > cols do
          true ->
            {model, nil}

          _ ->
            model = %{model | text: text, cursor: cursor + len}
            {model, trigger(model)}
        end
    end
  end

  def handle(%{text: text} = model, %{
        type: :mouse,
        action: :press,
        key: :bleft,
        x: mx,
        y: 0,
        flag: :none
      }) do
    cursor = min(mx, String.length(text))
    model = %{model | cursor: cursor}
    {model, nil}
  end

  def handle(model, _event), do: {model, nil}

  def render(model, canvas, theme) do
    %{
      cursor: cursor,
      password: password,
      size: {cols, rows},
      focused: focused,
      text: text
    } = model

    canvas = Canvas.fore(canvas, theme.(:fore, :normal))
    canvas = Canvas.back(canvas, theme.(:back, :normal))

    line = String.duplicate(" ", cols)

    canvas =
      for r <- 0..(rows - 1), reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          Canvas.write(canvas, line)
      end

    text =
      case password do
        true -> String.duplicate("*", String.length(text))
        _ -> text
      end

    text = String.pad_trailing(text, cols)
    canvas = Canvas.move(canvas, 0, 0)
    canvas = Canvas.write(canvas, text)

    # See: double focus, double cursor, or cursor override problem.
    # Trust the focused state.
    # focusable(model) would be useful as third condition.
    case {focused, cursor < cols} do
      {true, true} ->
        Canvas.cursor(canvas, cursor, 0)

      _ ->
        canvas
    end
  end

  defp trigger(%{on_change: on_change, text: text}) do
    resp = on_change.(text)
    {:text, text, resp}
  end

  defp check(model) do
    Check.assert_boolean(:focused, model.focused)
    Check.assert_point_2d(:origin, model.origin)
    Check.assert_point_2d(:size, model.size)
    Check.assert_boolean(:visible, model.visible)
    Check.assert_boolean(:enabled, model.enabled)
    Check.assert_gte(:findex, model.findex, -1)
    Check.assert_boolean(:password, model.password)
    Check.assert_string(:text, model.text)
    Check.assert_gte(:cursor, model.cursor, 0)
    Check.assert_function(:on_change, model.on_change, 1)
    Check.assert_function(:validate, model.validate, 1)
    model
  end
end
