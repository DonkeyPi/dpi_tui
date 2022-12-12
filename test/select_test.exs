defmodule SelectTest do
  use ExUnit.Case
  use Ash.Tui.Aliases
  use Ash.Tui.Events

  # Select complex state consists of items and selected properties
  # with internal extra properties: count, map and offset.
  test "basic select check" do
    initial = Select.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             enabled: true,
             findex: 0,
             class: nil,
             items: [],
             selected: -1,
             count: 0,
             map: %{},
             offset: 0,
             on_change: &Select.nop/1
           }

    on_change = fn value -> value end
    model = Select.init(items: [0, 1, 2], size: {10, 2}, on_change: on_change)

    # updates

    # selected explicitly updated to 0
    assert Select.update(%{model | selected: -1}, selected: 0) == model

    # update items (zero area)
    assert Select.update(initial, items: [0, 1]) == %{
             initial
             | items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2,
               selected: -1
           }

    # update items + size
    assert Select.update(initial, size: {0, 2}, items: [0, 1]) == %{
             initial
             | size: {0, 2},
               items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2,
               selected: 0
           }

    # update items + size + selected
    assert Select.update(initial, size: {0, 2}, items: [0, 1], selected: 1) == %{
             initial
             | size: {0, 2},
               items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2,
               selected: 1
           }

    # update items + size + selected (offset recalculated)
    assert Select.update(initial, size: {0, 1}, items: [0, 1], selected: 1) == %{
             initial
             | size: {0, 1},
               items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2,
               offset: 1,
               selected: 1
           }

    # selected recalculated to -1 (out of range)
    assert Select.update(initial, size: {0, 2}, items: [0, 1], selected: 2) == %{
             initial
             | size: {0, 2},
               items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2
           }

    # triggers

    # down key moves selection down
    assert Select.handle(model, @ev_kp_kdown) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    # page down key moves selection +rows down
    assert Select.handle(model, @ev_kp_pdown) ==
             {%{model | selected: 2, offset: 1}, {:item, 2, 2, {2, 2}}}

    # end key moves selection to the end
    assert Select.handle(model, @ev_kp_end) ==
             {%{model | selected: 2, offset: 1}, {:item, 2, 2, {2, 2}}}

    # mouse scroll down moves selection down
    assert Select.handle(model, @ev_ms_down) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    # up key moves selection up
    assert Select.handle(%{model | selected: 1}, @ev_kp_kup) ==
             {model, {:item, 0, 0, {0, 0}}}

    # page up key moves selection -rows up
    assert Select.handle(%{model | selected: 2}, @ev_kp_pup) ==
             {model, {:item, 0, 0, {0, 0}}}

    # home key move selection to the start
    assert Select.handle(%{model | selected: 2}, @ev_kp_home) ==
             {model, {:item, 0, 0, {0, 0}}}

    # mouse scroll up moves selection up
    assert Select.handle(%{model | selected: 1}, @ev_ms_up) ==
             {model, {:item, 0, 0, {0, 0}}}

    # mouse click selects clicked item
    assert Select.handle(model, ev_mp_left(0, 1)) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    # mouse click selects clicked item
    assert Select.handle(model, ev_mp_left(0, 2)) ==
             {%{model | selected: 2, offset: 1}, {:item, 2, 2, {2, 2}}}

    # retriggers

    assert Select.handle(model, @ev_kp_trigger) == {model, {:item, 0, 0, {0, 0}}}

    # nops

    # up key wont go beyond start
    assert Select.handle(model, @ev_kp_kup) == {model, nil}

    # page up key wont go beyond start
    assert Select.handle(model, @ev_kp_pup) == {model, nil}

    # home key wont go beyond start
    assert Select.handle(model, @ev_kp_home) == {model, nil}

    # mouse scroll up wont go beyond start
    assert Select.handle(model, @ev_ms_up) == {model, nil}

    # down key wont go beyond end
    assert Select.handle(%{model | selected: 2}, @ev_kp_kdown) ==
             {%{model | selected: 2, offset: 1}, nil}

    # page down key wont go beyond end
    assert Select.handle(%{model | selected: 2}, @ev_kp_pdown) ==
             {%{model | selected: 2, offset: 1}, nil}

    # end key wont go beyond end
    assert Select.handle(%{model | selected: 2}, @ev_kp_end) ==
             {%{model | selected: 2, offset: 1}, nil}

    # mouse scroll down wont go beyond end
    assert Select.handle(%{model | selected: 2}, @ev_ms_down) ==
             {%{model | selected: 2, offset: 1}, nil}

    # click on selected item wont retrigger
    assert Select.handle(model, ev_mp_left(0, 0)) == {model, nil}

    # click on unused space wont trigger
    assert Select.handle(model, ev_mp_left(0, 3)) == {model, nil}

    # recalculate

    # selected/offset reset to 0 (any key should correct it)
    assert Select.handle(%{model | selected: -1}, @ev_kp_kup) ==
             {model, {:item, 0, 0, {0, 0}}}

    # selected/offset reset to 0 (any mouse should correct it)
    assert Select.handle(%{model | selected: -1}, @ev_ms_up) ==
             {model, {:item, 0, 0, {0, 0}}}
  end
end
