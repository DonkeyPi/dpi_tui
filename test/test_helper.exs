ExUnit.start()

# FIXME understand why Button requires the outer `use Ash.Tui`
defmodule ControlTest do
  use ExUnit.Case
  use Ash.Tui.Aliases
  use Ash.Tui.Colors
  use Ash.Tui.Const

  defmacro __using__(_) do
    quote do
      use Ash.Tui.Aliases
      use Ash.Tui.Colors
      use Ash.Tui.Const
      import ControlTest
    end
  end

  def nop(), do: :nop
  def nop(value), do: {:nop, value}

  # Per feature testing is in this case better than per control
  # testing. It makes clear the differences between controls.

  def common_checks(module, opts \\ []) do
    accesors_checks(module, opts)
    navigation_checks(module, opts)
    update_checks(module, opts)
    triggers_checks(module, opts)
    nops_checks(module, opts)
  end

  def accesors_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)

    # this should make any focusable control focusable
    focusable = %{
      enabled: true,
      visible: true,
      findex: 0,
      on_click: &nop/0,
      on_change: &nop/1,
      root: false,
      children: %{},
      index: []
    }

    # complement to make panel focusable
    focusable = %{focusable | children: %{id: {Button, focusable}}, index: [:id]}

    # simple getters
    assert module.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert module.visible(%{visible: :visible}) == :visible
    assert module.shortcut(%{shortcut: :shortcut}) == if(button?, do: :shortcut, else: nil)

    # focused getter
    if input? or panel? do
      assert module.focused(%{focused: :focused}) == :focused
    else
      assert module.focused(%{focused: :focused}) == false
    end

    # focused setter
    if input? or panel? do
      assert module.focused(%{focused: nil}, :focused) == %{focused: :focused}
    else
      assert module.focused(%{focused: nil}, :focused) == %{focused: nil}
    end

    # findex getter
    if input? or panel? do
      assert module.findex(%{findex: :findex}) == :findex
    else
      assert module.findex(%{findex: :findex}) == -1
    end

    # modal getter
    if panel? do
      assert module.modal(%{root: :root}) == :root
    else
      assert module.modal(:state) == false
    end

    # children getter
    if panel? do
      assert module.children(%{children: nil, index: []}) == []
    else
      assert module.children(:state) == []
      assert module.children(:state, []) == :state
    end

    # focusable getter
    assert module.focusable(focusable) == (input? or panel?)
    assert module.focusable(%{focusable | enabled: false}) == false
    assert module.focusable(%{focusable | visible: false}) == false
    assert module.focusable(%{focusable | findex: -1}) == false

    if panel? do
      assert module.focusable(%{focusable | root: true}) == false
      assert module.focusable(%{focusable | index: []}) == false
    else
      assert module.focusable(%{focusable | on_click: nil}) ==
               if(input?, do: not button?, else: false)

      assert module.focusable(%{focusable | on_change: nil}) ==
               if(input?, do: button?, else: false)
    end

    # children setter (except Panel)
    if panel? do
      # returns a complex state
      # assert module.children(%{}, []) == %{children: %{}, index: []}
    else
      assert module.children(:state) == []
      assert module.children(:state, []) == :state
    end
  end

  def navigation_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)

    # navigation (except Panel)
    if input? do
      assert module.handle(%{}, %{type: :key, action: :press, key: :tab}) ==
               {%{}, {:focus, :next}}

      assert module.handle(%{}, %{type: :key, action: :press, key: :tab, flag: @rtab}) ==
               {%{}, {:focus, :prev}}
    else
      assert module.handle(%{}, %{type: :key, action: :press, key: :tab}) == {%{}, nil}

      assert module.handle(%{}, %{type: :key, action: :press, key: :tab, flag: @rtab}) ==
               {%{}, nil}
    end

    case module do
      Button ->
        assert module.handle(%{}, %{type: :key, action: :press, key: :kdown}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kright}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kup}) ==
                 {%{}, {:focus, :prev}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kleft}) ==
                 {%{}, {:focus, :prev}}

      Checkbox ->
        assert module.handle(%{}, %{type: :key, action: :press, key: :enter}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kdown}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kright}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kup}) ==
                 {%{}, {:focus, :prev}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kleft}) ==
                 {%{}, {:focus, :prev}}

      Input ->
        assert module.handle(%{}, %{type: :key, action: :press, key: :enter}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kdown}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kup}) ==
                 {%{}, {:focus, :prev}}

      Radio ->
        assert module.handle(%{}, %{type: :key, action: :press, key: :enter}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kdown}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kup}) ==
                 {%{}, {:focus, :prev}}

      Select ->
        assert module.handle(%{}, %{type: :key, action: :press, key: :enter}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kright}) ==
                 {%{}, {:focus, :next}}

        assert module.handle(%{}, %{type: :key, action: :press, key: :kleft}) ==
                 {%{}, {:focus, :prev}}

      _ ->
        nil
    end
  end

  def update_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)

    # update
    initial = module.init()

    # origin update
    assert module.update(initial, origin: {0, 0}) == initial
    assert module.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}

    # visible update
    assert module.update(initial, visible: true) == initial
    assert module.update(initial, visible: false) == %{initial | visible: false}

    # enabled update
    if input? or panel? do
      assert module.update(initial, enabled: true) == initial
      assert module.update(initial, enabled: false) == %{initial | enabled: false}
    end

    # focused update (always dropped)
    if input? or panel? do
      assert module.update(initial, focused: :dropped) == initial
    end

    # findex update
    if input? or panel? do
      assert module.update(initial, findex: 0) == initial
      assert module.update(initial, findex: -1) == %{initial | findex: -1}
    end

    # size update
    assert module.update(initial, size: {0, 2}) == %{initial | size: {0, 2}}

    case module do
      Button -> assert module.update(initial, size: {2, 1}) == initial
      Checkbox -> assert module.update(initial, size: {3, 1}) == initial
      Frame -> assert module.update(initial, size: {0, 0}) == initial
      Input -> assert module.update(initial, size: {0, 1}) == initial
      Label -> assert module.update(initial, size: {0, 1}) == initial
      Panel -> assert module.update(initial, size: {0, 0}) == initial
      Radio -> assert module.update(initial, size: {0, 0}) == initial
      Select -> assert module.update(initial, size: {0, 0}) == initial
      _ -> nil
    end

    # control specific updates
    case module do
      Button ->
        on_click = fn -> :click end
        assert module.update(initial, theme: :default) == initial
        assert module.update(initial, text: "") == initial
        assert module.update(initial, shortcut: nil) == initial
        assert module.update(initial, on_click: nil) == initial
        assert module.update(initial, theme: :theme) == %{initial | theme: :theme}
        assert module.update(initial, text: "text") == %{initial | text: "text"}
        assert module.update(initial, shortcut: :esc) == %{initial | shortcut: :esc}
        assert module.update(initial, on_click: on_click) == %{initial | on_click: on_click}

      Checkbox ->
        on_change = fn checked -> checked end
        assert module.update(initial, theme: :default) == initial
        assert module.update(initial, text: "") == initial
        assert module.update(initial, checked: false) == initial
        assert module.update(initial, on_change: nil) == initial
        assert module.update(initial, theme: :theme) == %{initial | theme: :theme}
        assert module.update(initial, text: "text") == %{initial | text: "text"}
        assert module.update(initial, checked: true) == %{initial | checked: true}
        assert module.update(initial, on_change: on_change) == %{initial | on_change: on_change}

      Frame ->
        not_used = Theme.get(:default).not_used
        assert module.update(initial, bracket: false) == initial
        assert module.update(initial, style: :single) == initial
        assert module.update(initial, text: "") == initial
        assert module.update(initial, back: Theme.get(:default).back_readonly) == initial
        assert module.update(initial, fore: Theme.get(:default).fore_readonly) == initial
        assert module.update(initial, bracket: true) == %{initial | bracket: true}
        assert module.update(initial, style: :double) == %{initial | style: :double}
        assert module.update(initial, text: "text") == %{initial | text: "text"}
        assert module.update(initial, back: not_used) == %{initial | back: not_used}
        assert module.update(initial, fore: not_used) == %{initial | fore: not_used}

      Input ->
        on_change = fn value -> value end
        assert module.update(initial, cursor: :dropped) == initial
        assert module.update(initial, theme: :default) == initial
        assert module.update(initial, password: false) == initial
        assert module.update(initial, text: "") == initial
        assert module.update(initial, on_change: nil) == initial
        assert module.update(initial, theme: :theme) == %{initial | theme: :theme}
        assert module.update(initial, password: true) == %{initial | password: true}
        assert module.update(initial, text: "text") == %{initial | text: "text", cursor: 4}

        assert module.update(initial, text: "text", cursor: 1) == %{
                 initial
                 | text: "text",
                   cursor: 4
               }

        assert module.update(initial, cursor: 1, text: "text") == %{
                 initial
                 | text: "text",
                   cursor: 4
               }

        assert module.update(initial, on_change: on_change) == %{
                 initial
                 | on_change: on_change
               }

      Label ->
        not_used = Theme.get(:default).not_used
        assert module.update(initial, text: "") == initial
        assert module.update(initial, back: Theme.get(:default).back_readonly) == initial
        assert module.update(initial, fore: Theme.get(:default).fore_readonly) == initial
        assert module.update(initial, text: "text") == %{initial | text: "text"}
        assert module.update(initial, back: not_used) == %{initial | back: not_used}
        assert module.update(initial, fore: not_used) == %{initial | fore: not_used}

      Panel ->
        assert module.update(initial, root: :dropped) == initial
        assert module.update(initial, index: :dropped) == initial
        assert module.update(initial, children: :dropped) == initial
        assert module.update(initial, focus: :dropped) == initial

      Radio ->
        on_change = fn {index, item} -> {index, item} end
        assert module.update(initial, count: :dropped) == initial
        assert module.update(initial, map: :dropped) == initial
        assert module.update(initial, theme: :default) == initial
        assert module.update(initial, items: []) == initial
        # any selected value will be recalculated to initial -1
        assert module.update(initial, selected: -1) == initial
        assert module.update(initial, selected: 0) == initial
        assert module.update(initial, selected: 1) == initial
        assert module.update(initial, on_change: nil) == initial
        assert module.update(initial, theme: :theme) == %{initial | theme: :theme}
        assert module.update(initial, on_change: on_change) == %{initial | on_change: on_change}

        assert module.update(initial, items: [0, 1]) == %{
                 initial
                 | items: [0, 1],
                   map: %{0 => 0, 1 => 1},
                   count: 2,
                   selected: 0
               }

        assert module.update(initial, items: [0, 1], selected: 1) == %{
                 initial
                 | items: [0, 1],
                   map: %{0 => 0, 1 => 1},
                   count: 2,
                   selected: 1
               }

      Select ->
        on_change = fn {index, item} -> {index, item} end
        assert module.update(initial, count: :dropped) == initial
        assert module.update(initial, map: :dropped) == initial
        assert module.update(initial, offset: :dropped) == initial
        # any selected value will be recalculated to initial -1
        assert module.update(initial, selected: -1) == initial
        assert module.update(initial, selected: 0) == initial
        assert module.update(initial, selected: 1) == initial
        assert module.update(initial, items: []) == initial
        assert module.update(initial, on_change: nil) == initial
        assert module.update(initial, theme: :theme) == %{initial | theme: :theme}
        assert module.update(initial, on_change: on_change) == %{initial | on_change: on_change}

        assert module.update(initial, items: [0, 1]) == %{
                 initial
                 | items: [0, 1],
                   map: %{0 => 0, 1 => 1},
                   count: 2,
                   selected: -1
               }

        assert module.update(initial, size: {0, 1}, items: [0, 1]) == %{
                 initial
                 | size: {0, 1},
                   items: [0, 1],
                   map: %{0 => 0, 1 => 1},
                   count: 2,
                   selected: 0
               }

        # selected recalculated to -1 (out of range)
        assert module.update(initial, size: {0, 1}, items: [0, 1], selected: 2) == %{
                 initial
                 | size: {0, 1},
                   items: [0, 1],
                   map: %{0 => 0, 1 => 1},
                   count: 2
               }

      _ ->
        nil
    end
  end

  def triggers_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)

    # triggers
  end

  def nops_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)

    # nop
    assert module.handle(%{}, :any) == {%{}, nil}
  end
end
