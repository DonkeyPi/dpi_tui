ExUnit.start()

defmodule TestMacros do
  defmacro __using__(_) do
    quote do
      use Ash.Tui.Aliases
      use Ash.Tui.Events
      import TestImports
      use TestColors
    end
  end
end

defmodule TestColors do
  defmacro __using__(_) do
    quote do
      @tcf_normal 0x01
      @tcb_normal 0x02
      @tcf_focused 0x03
      @tcb_focused 0x04
      @tcf_disabled 0x05
      @tcb_disabled 0x06
    end
  end
end

defmodule TestTheme do
  use Ash.Tui.Aliases
  use TestColors

  def get_style({:fore, _}, %{enabled: false}), do: @tcf_disabled
  def get_style({:back, _}, %{enabled: false}), do: @tcb_disabled
  def get_style({:fore, _}, %{focused: true}), do: @tcf_focused
  def get_style({:back, _}, %{focused: true}), do: @tcb_focused
  def get_style({:fore, _}, %{}), do: @tcf_normal
  def get_style({:back, _}, %{}), do: @tcb_normal
end

defmodule TestImports do
  use ExUnit.Case
  use Ash.Tui.Aliases
  alias Ash.Tui.Canvas
  use TestColors

  defp init(module, props) do
    model = module.init(props)
    %{module: module, model: model}
  end

  def button(props), do: init(Button, props)
  def checkbox(props), do: init(Checkbox, props)
  def frame(props), do: init(Frame, props)
  def label(props), do: init(Label, props)

  def render(map, cols, rows) do
    Theme.set(TestTheme)
    bounds = map.module.bounds(map.model)
    canvas = Canvas.new(cols, rows)
    canvas = Canvas.push(canvas, bounds)
    module = map.module
    model = map.model
    theme = Theme.get(:id, module, model)
    canvas = module.render(model, canvas, theme)
    canvas = Canvas.pop(canvas)
    Map.put(map, :canvas, canvas)
  end

  def assert(map, text, x, y, fg, bg) do
    text1 = String.to_charlist(text)
    len = length(text1)
    data = map.canvas.data

    cells =
      for i <- x..(x + len - 1) do
        case Map.get(data, {i, y}) do
          nil -> {nil, nil, nil}
          cell -> cell
        end
      end

    fg1 = for {_, _, _} <- cells, do: fg
    bg1 = for {_, _, _} <- cells, do: bg

    text2 = for {c, _, _} <- cells, do: c
    fg2 = for {_, f, _} <- cells, do: f
    bg2 = for {_, _, b} <- cells, do: b

    assert text1 == text2
    assert fg1 == fg2
    assert bg1 == bg2
    map
  end

  def focused(map, focused) do
    model = map.module.focused(map.model, focused)
    Map.put(map, :model, model)
  end

  defp update(map, prop, value) do
    model = map.module.update(map.model, [{prop, value}])
    Map.put(map, :model, model)
  end

  def enabled(map, enabled) do
    update(map, :enabled, enabled)
  end

  def checked(map, checked) do
    update(map, :checked, checked)
  end

  def size(map, size) do
    update(map, :size, size)
  end

  def text(map, text) do
    update(map, :text, text)
  end

  def align(map, align) do
    update(map, :align, align)
  end

  def handle(map, event, result \\ nil) do
    {model, ^result} = map.module.handle(map.model, event)
    Map.put(map, :model, model)
  end
end
