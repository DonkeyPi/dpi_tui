ExUnit.start()

defmodule TestMacros do
  defmacro __using__(_) do
    quote do
      use TestColors
      import TestImports
    end
  end
end

defmodule TestColors do
  defmacro __using__(_) do
    quote do
      @bf_normal 1
      @bb_normal 2
      @bf_focused 3
      @bb_focused 4
      @bf_disabled 5
      @bb_disabled 6
    end
  end
end

defmodule TestTheme do
  use Ash.Tui.Aliases
  use TestColors

  def get_style({:fore, _}, %{type: Button, enabled: false}), do: @bf_disabled
  def get_style({:back, _}, %{type: Button, enabled: false}), do: @bb_disabled
  def get_style({:fore, _}, %{type: Button, focused: true}), do: @bf_focused
  def get_style({:back, _}, %{type: Button, focused: true}), do: @bb_focused
  def get_style({:fore, _}, %{type: Button}), do: @bf_normal
  def get_style({:back, _}, %{type: Button}), do: @bb_normal
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

  def button(props) do
    init(Button, props)
  end

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

  def enabled(map, enabled) do
    model = map.module.update(map.model, enabled: enabled)
    Map.put(map, :model, model)
  end
end
