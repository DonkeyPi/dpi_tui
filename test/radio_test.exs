defmodule RadioTest do
  use ExUnit.Case
  use ControlTest

  test "basic radio check" do
    common_checks(Radio, input?: true)

    initial = Radio.init()

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
             on_change: &Radio.nop/1
           }

    # getters/setters
    assert Radio.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Radio.visible(%{visible: :visible}) == :visible
    assert Radio.focusable(%{initial | enabled: false}) == false
    assert Radio.focusable(%{initial | visible: false}) == false
    assert Radio.focusable(%{initial | on_change: nil}) == false
    assert Radio.focusable(%{initial | findex: -1}) == false
    assert Radio.focused(%{focused: false}) == false
    assert Radio.focused(%{focused: true}) == true
    assert Radio.focused(initial, true) == %{initial | focused: true}
    assert Radio.refocus(:state, :dir) == :state
    assert Radio.findex(%{findex: 0}) == 0
    assert Radio.shortcut(:state) == nil
    assert Radio.children(:state) == []
    assert Radio.children(:state, []) == :state
    assert Radio.modal(:state) == false

    # update
    on_change = fn {index, item} -> {index, item} end
    assert Radio.update(initial, focused: :any) == initial
    assert Radio.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Radio.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Radio.update(initial, visible: false) == %{initial | visible: false}
    assert Radio.update(initial, enabled: false) == %{initial | enabled: false}
    assert Radio.update(initial, findex: 1) == %{initial | findex: 1}
    assert Radio.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Radio.update(initial, selected: 0) == initial
    assert Radio.update(initial, count: -1) == initial
    assert Radio.update(initial, map: :map) == initial
    assert Radio.update(initial, on_change: on_change) == %{initial | on_change: on_change}
    assert Radio.update(initial, on_change: nil) == initial

    # update items
    assert Radio.update(initial, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 0,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update items + selected
    assert Radio.update(initial, items: [:item0, :item1], selected: 1) == %{
             initial
             | items: [:item0, :item1],
               selected: 1,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update selected + items
    assert Radio.update(initial, selected: 1, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 1,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # recalc
    assert Radio.update(%{initial | selected: 1}, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 0,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # navigation
    assert Radio.handle(%{}, %{type: :key, action: :press, key: :tab}) == {%{}, {:focus, :next}}
    assert Radio.handle(%{}, %{type: :key, action: :press, key: :kdown}) == {%{}, {:focus, :next}}

    assert Radio.handle(%{}, %{type: :key, action: :press, key: :tab, flag: @rtab}) ==
             {%{}, {:focus, :prev}}

    assert Radio.handle(%{}, %{type: :key, action: :press, key: :kup}) == {%{}, {:focus, :prev}}
    assert Radio.handle(%{}, %{type: :key, action: :press, key: :enter}) == {%{}, {:focus, :next}}

    # triggers
    sample = Radio.init(items: [:item0, :item1, :item2], size: {10, 1}, on_change: on_change)

    assert Radio.handle(sample, %{type: :key, action: :press, key: :kright}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Radio.handle(sample, %{type: :key, action: :press, key: :end}) ==
             {%{sample | selected: 2}, {:item, 2, :item2, {2, :item2}}}

    assert Radio.handle(sample, %{type: :mouse, action: :scroll, dir: :down}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Radio.handle(%{sample | selected: 1}, %{type: :key, action: :press, key: :kleft}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.handle(%{sample | selected: 2}, %{type: :key, action: :press, key: :home}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.handle(%{sample | selected: 1}, %{type: :mouse, action: :scroll, dir: :up}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.handle(sample, %{type: :mouse, action: :press, x: 7}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Radio.handle(%{sample | selected: 2}, %{type: :mouse, action: :press, x: 3}) ==
             {%{sample | selected: 0}, {:item, 0, :item0, {0, :item0}}}

    # retriggers
    assert Radio.handle(sample, %{type: :key, action: :press, key: :enter, flag: @renter}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    # nops
    assert Radio.handle(%{}, nil) == {%{}, nil}
    assert Radio.handle(initial, %{type: :mouse}) == {initial, nil}
    assert Radio.handle(initial, %{type: :key}) == {initial, nil}
    assert Radio.handle(sample, %{type: :key, action: :press, key: :kleft}) == {sample, nil}
    assert Radio.handle(sample, %{type: :key, action: :press, key: :home}) == {sample, nil}
    assert Radio.handle(sample, %{type: :mouse, action: :scroll, dir: :up}) == {sample, nil}

    assert Radio.handle(%{sample | selected: 2}, %{type: :key, action: :press, key: :kright}) ==
             {%{sample | selected: 2}, nil}

    assert Radio.handle(%{sample | selected: 2}, %{type: :key, action: :press, key: :end}) ==
             {%{sample | selected: 2}, nil}

    assert Radio.handle(%{sample | selected: 2}, %{type: :mouse, action: :scroll, dir: :down}) ==
             {%{sample | selected: 2}, nil}

    assert Radio.handle(%{sample | selected: 2}, %{type: :mouse, action: :press, x: 5}) ==
             {%{sample | selected: 2}, nil}

    # recalculate

    # offset (any key/mouse should correct it)
    assert Radio.handle(%{sample | selected: -1}, %{type: :key, action: :press, key: :kleft}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.handle(%{sample | selected: -1}, %{type: :mouse, action: :scroll, dir: :up}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.update(%{sample | selected: -1}, selected: 0) == sample
  end
end
