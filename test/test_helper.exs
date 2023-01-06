ExUnit.start()

defmodule Buffer do
  defp put(state), do: Process.put(__MODULE__, state)

  def get(), do: Process.get(__MODULE__)

  def start(data \\ ""), do: put(data)

  def add(data) do
    put(get() <> data)
  end
end

defmodule TestMacros do
  defmacro __using__(_) do
    quote do
      alias Dpi.Tui.Canvas
      use Dpi.Tui.Aliases
      use Dpi.Tui.Events
      use Dpi.Tui.Colors
      import TestImports
      use TestColors
    end
  end
end

defmodule TestColors do
  defmacro __using__(_) do
    quote do
      # > 16 to avoid collision with canvas defaults
      @tcf_normal 0x11
      @tcb_normal 0x12
      @tcf_focused 0x13
      @tcb_focused 0x14
      @tcf_disabled 0x15
      @tcb_disabled 0x16
      @tcf_selected 0x17
      @tcb_selected 0x18
      @tcf_invalid 0x19
      @tcb_invalid 0x1A

      @tc_normal :normal
      @tc_focused :focused
      @tc_disabled :disabled
      @tc_selected :selected
      @tc_invalid :invalid

      def get_color(:fore, {fore, _}), do: fore
      def get_color(:back, {_, back}), do: back
      def get_color(:fore, :normal), do: @tcf_normal
      def get_color(:back, :normal), do: @tcb_normal
      def get_color(:fore, :focused), do: @tcf_focused
      def get_color(:back, :focused), do: @tcb_focused
      def get_color(:fore, :disabled), do: @tcf_disabled
      def get_color(:back, :disabled), do: @tcb_disabled
      def get_color(:fore, :selected), do: @tcf_selected
      def get_color(:back, :selected), do: @tcb_selected
      def get_color(:fore, :invalid), do: @tcf_invalid
      def get_color(:back, :invalid), do: @tcb_invalid
    end
  end
end

defmodule TestTheme do
  use Dpi.Tui.Aliases
  use TestColors

  def get_style(:back, _, %{class: %{back: back}}), do: back
  def get_style(:fore, _, %{class: %{fore: fore}}), do: fore
  def get_style(:fore, :selected, %{}), do: @tcf_selected
  def get_style(:back, :selected, %{}), do: @tcb_selected
  def get_style(:fore, _, %{valid: false}), do: @tcf_invalid
  def get_style(:back, _, %{valid: false}), do: @tcb_invalid
  def get_style(:fore, _, %{enabled: false}), do: @tcf_disabled
  def get_style(:back, _, %{enabled: false}), do: @tcb_disabled
  def get_style(:fore, _, %{focused: true}), do: @tcf_focused
  def get_style(:back, _, %{focused: true}), do: @tcb_focused
  def get_style(:fore, _, %{}), do: @tcf_normal
  def get_style(:back, _, %{}), do: @tcb_normal
end

defmodule TestImports do
  use ExUnit.Case
  use Dpi.Tui.Aliases
  alias Dpi.Tui.Canvas
  use TestColors

  defp init(module, props) do
    model = module.init(props)
    %{module: module, model: model, momos: %{}}
  end

  defp add(map, module, props) do
    model = module.init(props)
    %{map | module: module, model: model}
  end

  def get(map, key), do: map[key]

  def button(props \\ []), do: init(Button, props)
  def button(maps, props), do: add(maps, Button, props)
  def checkbox(props \\ []), do: init(Checkbox, props)
  def checkbox(maps, props), do: add(maps, Checkbox, props)
  def frame(props \\ []), do: init(Frame, props)
  def frame(maps, props), do: add(maps, Frame, props)
  def label(props \\ []), do: init(Label, props)
  def label(maps, props), do: add(maps, Label, props)
  def input(props \\ []), do: init(Input, props)
  def input(maps, props), do: add(maps, Input, props)
  def select(props \\ []), do: init(Select, props)
  def select(maps, props), do: add(maps, Select, props)
  def radio(props \\ []), do: init(Radio, props)
  def radio(maps, props), do: add(maps, Radio, props)
  def panel(props \\ []), do: init(Panel, props)
  def panel(maps, props), do: add(maps, Panel, props)

  def save(map, id) do
    momo = {map.module, map.model}
    momos = Map.put(map.momos, id, momo)
    Map.put(map, :momos, momos)
  end

  def restore(map, id) do
    {module, model} = Map.fetch!(map.momos, id)
    %{map | module: module, model: model}
  end

  def assert_diff(map, diff) do
    canvas2 = map.canvas
    cols = canvas2.cols
    rows = canvas2.rows
    canvas1 = Canvas.new(cols, rows)
    diff1 = Canvas.diff(canvas1, canvas2)
    assert diff1 == diff
    map
  end

  def assert_color(map, text, xy, color) do
    case map do
      %{module: Radio} -> assert_color(map, text, xy, 0, color)
      _ -> assert_color(map, text, 0, xy, color)
    end
  end

  def assert_color(map, text, x, y, color) do
    fg = get_color(:fore, color)
    bg = get_color(:back, color)
    text1 = String.to_charlist(text)
    len = length(text1)
    data = map.canvas.data

    cells =
      for i <- x..(x + len - 1) do
        case Map.get(data, {i, y}) do
          nil -> {nil, nil, nil, nil}
          cell -> cell
        end
      end

    fg1 = for {_, _, _, _, _} <- cells, do: fg
    bg1 = for {_, _, _, _, _} <- cells, do: bg

    text2 = for {c, _, _, _, _} <- cells, do: c
    fg2 = for {_, f, _, _, _} <- cells, do: f
    bg2 = for {_, _, b, _, _} <- cells, do: b

    assert text1 == text2
    assert fg1 == fg2
    assert bg1 == bg2

    map
  end

  def assert_cursor(map, text, y, cx) do
    text1 = String.to_charlist(text)
    len = length(text1)
    data = map.canvas.data
    x = 0

    cells =
      for i <- x..(x + len - 1) do
        case Map.get(data, {i, y}) do
          nil -> {nil, nil, nil, nil}
          cell -> cell
        end
      end

    text2 = for {c, _, _, _, _} <- cells, do: c

    assert text1 == text2

    case cx do
      false ->
        {enabled, _, _} = map.canvas.cursor
        assert false == enabled

      cx ->
        {enabled, px, py} = map.canvas.cursor
        assert {true, cx, y} == {enabled, px, py}
    end

    map
  end

  def render(map, cols, rows) do
    Theme.set(TestTheme)
    canvas = Canvas.new(cols, rows)
    module = map.module
    model = map.model
    bounds = module.bounds(model)
    canvas = Canvas.push(canvas, bounds)
    theme = Theme.get(:id, module, model)
    canvas = module.render(model, canvas, theme)
    canvas = Canvas.pop(canvas)
    Map.put(map, :canvas, canvas)
  end

  def render(map) do
    {ox, oy, cols, rows} = map.module.bounds(map.model)
    render(map, cols + 2 * ox, rows + 2 * oy)
  end

  def focused(map, focused) do
    model = map.module.focused(map.model, focused)
    Map.put(map, :model, model)
  end

  def update(map, props) do
    model = map.module.update(map.model, props)
    Map.put(map, :model, model)
  end

  def update(map, id, props) do
    {module, model} = map.model.children[id]
    model = module.update(model, props)
    child = {module, model}
    module = map.module
    model = map.model
    children = module.children(model)
    children = Keyword.replace!(children, id, child)
    model = module.children(model, children)
    %{map | module: module, model: model}
  end

  def put(map, props) do
    props = Enum.into(props, %{})
    model = Map.merge(map.model, props)
    Map.put(map, :model, model)
  end

  def put(map, id, props) do
    props = Enum.into(props, %{})
    {module, model} = map.model.children[id]
    model = Map.merge(model, props)
    child = {module, model}
    module = map.module
    model = map.model
    children = module.children(model)
    children = Keyword.replace!(children, id, child)
    model = module.children(model, children)
    %{map | module: module, model: model}
  end

  def enabled(map, enabled), do: update(map, enabled: enabled)
  def checked(map, checked), do: update(map, checked: checked)
  def size(map, size), do: update(map, size: size)
  def text(map, text), do: update(map, text: text)
  def align(map, align), do: update(map, align: align)
  def password(map, password), do: update(map, password: password)
  def selected(map, selected), do: update(map, selected: selected)
  def cursor(map, cursor), do: put(map, cursor: cursor)

  def children(map, children) do
    children =
      case Keyword.keyword?(children) do
        true ->
          children

        _ ->
          momos = map.momos

          for id <- children do
            {id, Map.fetch!(momos, id)}
          end
      end

    model = map.module.children(map.model, children)
    Map.put(map, :model, model)
  end

  def handle(map, event, result \\ nil) do
    {model, ^result} = map.module.handle(map.model, event)
    Map.put(map, :model, model)
  end

  def dump_item(map, item) do
    IO.inspect(Map.get(map, item))
    map
  end

  def dump_curr(map) do
    IO.inspect({map.module, map.model})
    map
  end

  def dump_momo(map, id) do
    IO.inspect(map.momos[id])
    map
  end
end
