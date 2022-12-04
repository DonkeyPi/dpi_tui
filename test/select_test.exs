defmodule SelectTest do
  use ExUnit.Case
  use ControlTest

  test "basic select check" do
    control_test(Select, input?: true)

    initial = Select.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             enabled: true,
             findex: 0,
             theme: :default,
             items: [],
             selected: -1,
             count: 0,
             map: %{},
             offset: 0,
             on_change: &Select.nop/1
           }

    # getters/setters
    assert Select.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Select.visible(%{visible: :visible}) == :visible
    assert Select.focusable(%{initial | enabled: false}) == false
    assert Select.focusable(%{initial | visible: false}) == false
    assert Select.focusable(%{initial | on_change: nil}) == false
    assert Select.focusable(%{initial | findex: -1}) == false
    assert Select.focused(%{focused: false}) == false
    assert Select.focused(%{focused: true}) == true
    assert Select.focused(initial, true) == %{initial | focused: true}
    assert Select.refocus(:state, :dir) == :state
    assert Select.findex(%{findex: 0}) == 0
    assert Select.shortcut(:state) == nil
    assert Select.children(:state) == []
    assert Select.children(:state, []) == :state
    assert Select.modal(:state) == false

    # update
    on_change = fn {index, item} -> {index, item} end
    assert Select.update(initial, focused: :any) == initial
    assert Select.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Select.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Select.update(initial, visible: false) == %{initial | visible: false}
    assert Select.update(initial, enabled: false) == %{initial | enabled: false}
    assert Select.update(initial, findex: 1) == %{initial | findex: 1}
    assert Select.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Select.update(initial, items: []) == initial
    assert Select.update(initial, selected: 0) == initial
    assert Select.update(initial, count: -1) == initial
    assert Select.update(initial, map: :map) == initial
    assert Select.update(initial, offset: -1) == initial
    assert Select.update(initial, on_change: on_change) == %{initial | on_change: on_change}
    assert Select.update(initial, on_change: nil) == initial

    # navigation
    assert Select.handle(%{}, %{type: :key, key: :tab}) == {%{}, {:focus, :next}}
    assert Select.handle(%{}, %{type: :key, key: :kright}) == {%{}, {:focus, :next}}
    assert Select.handle(%{}, %{type: :key, key: :tab, flag: @rtab}) == {%{}, {:focus, :prev}}
    assert Select.handle(%{}, %{type: :key, key: :kleft}) == {%{}, {:focus, :prev}}
    assert Select.handle(%{}, %{type: :key, key: :enter}) == {%{}, {:focus, :next}}

    # triggers
    sample = Select.init(items: [:item0, :item1, :item2], size: {10, 2}, on_change: on_change)

    assert Select.handle(sample, %{type: :key, key: :kdown}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Select.handle(sample, %{type: :key, key: :pdown}) ==
             {%{sample | selected: 2, offset: 1}, {:item, 2, :item2, {2, :item2}}}

    assert Select.handle(sample, %{type: :key, key: :end}) ==
             {%{sample | selected: 2, offset: 1}, {:item, 2, :item2, {2, :item2}}}

    assert Select.handle(sample, %{type: :mouse, action: :scroll, dir: :down}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Select.handle(%{sample | selected: 1}, %{type: :key, key: :kup}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(%{sample | selected: 2}, %{type: :key, key: :pup}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(%{sample | selected: 2}, %{type: :key, key: :home}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(%{sample | selected: 1}, %{type: :mouse, action: :scroll, dir: :up}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(sample, %{type: :mouse, action: :press, y: 1}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Select.handle(sample, %{type: :mouse, action: :press, y: 2}) ==
             {%{sample | selected: 2, offset: 1}, {:item, 2, :item2, {2, :item2}}}

    # retriggers
    assert Select.handle(sample, %{type: :key, key: :enter, flag: @renter}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    # nops
    assert Select.handle(%{}, nil) == {%{}, nil}
    assert Select.handle(initial, %{type: :mouse}) == {initial, nil}
    assert Select.handle(initial, %{type: :key}) == {initial, nil}
    assert Select.handle(sample, %{type: :key, key: :kup}) == {sample, nil}
    assert Select.handle(sample, %{type: :key, key: :pup}) == {sample, nil}
    assert Select.handle(sample, %{type: :key, key: :home}) == {sample, nil}
    assert Select.handle(sample, %{type: :mouse, action: :scroll, dir: :up}) == {sample, nil}

    assert Select.handle(%{sample | selected: 2}, %{type: :key, key: :kdown}) ==
             {%{sample | selected: 2, offset: 1}, nil}

    assert Select.handle(%{sample | selected: 2}, %{type: :key, key: :pdown}) ==
             {%{sample | selected: 2, offset: 1}, nil}

    assert Select.handle(%{sample | selected: 2}, %{type: :key, key: :end}) ==
             {%{sample | selected: 2, offset: 1}, nil}

    assert Select.handle(%{sample | selected: 2}, %{type: :mouse, action: :scroll, dir: :down}) ==
             {%{sample | selected: 2, offset: 1}, nil}

    assert Select.handle(sample, %{type: :mouse, action: :press, y: 0}) ==
             {sample, nil}

    assert Select.handle(sample, %{type: :mouse, action: :press, y: 3}) ==
             {sample, nil}

    # recalculate

    # offset (any key/mouse should correct it)
    assert Select.handle(%{sample | selected: -1}, %{type: :key, key: :kup}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(%{sample | selected: -1}, %{type: :mouse, action: :scroll, dir: :up}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.update(%{sample | selected: -1}, selected: 0) == sample

    # update items
    assert Select.update(initial, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 0,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update items + selected
    assert Select.update(initial, items: [:item0, :item1], selected: 1) == %{
             initial
             | items: [:item0, :item1],
               selected: 1,
               offset: 1,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update selected + items
    assert Select.update(initial, selected: 1, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 1,
               offset: 1,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update items with invalid offset
    assert Select.update(%{initial | selected: 1, offset: 2}, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 0,
               offset: 0,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }
  end
end
