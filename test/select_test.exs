defmodule SelectTest do
  use ExUnit.Case
  use ControlTest

  test "basic select check" do
    ControlTest.common_checks(Select, input?: true)

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

    on_change = fn value -> value end

    # updates

    # update items (zero area)
    assert Select.update(initial, items: [0, 1]) == %{
             initial
             | items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2,
               selected: -1
           }

    # update items + size
    assert Select.update(initial, size: {0, 1}, items: [0, 1]) == %{
             initial
             | size: {0, 1},
               items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2,
               selected: 0
           }

    # selected recalculated to -1 (out of range)
    assert Select.update(initial, size: {0, 1}, items: [0, 1], selected: 2) == %{
             initial
             | size: {0, 1},
               items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2
           }

    # triggers
    model = Select.init(items: [0, 1, 2], size: {10, 2}, on_change: on_change)

    assert Select.handle(model, @ev_kp_kdown) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    assert Select.handle(model, @ev_kp_pdown) ==
             {%{model | selected: 2, offset: 1}, {:item, 2, 2, {2, 2}}}

    assert Select.handle(model, @ev_kp_end) ==
             {%{model | selected: 2, offset: 1}, {:item, 2, 2, {2, 2}}}

    assert Select.handle(model, @ev_ms_down) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    assert Select.handle(%{model | selected: 1}, @ev_kp_kup) ==
             {model, {:item, 0, 0, {0, 0}}}

    assert Select.handle(%{model | selected: 2}, @ev_kp_pup) ==
             {model, {:item, 0, 0, {0, 0}}}

    assert Select.handle(%{model | selected: 2}, @ev_kp_home) ==
             {model, {:item, 0, 0, {0, 0}}}

    assert Select.handle(%{model | selected: 1}, @ev_ms_up) ==
             {model, {:item, 0, 0, {0, 0}}}

    assert Select.handle(model, %{type: :mouse, action: :press, y: 1}) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    assert Select.handle(model, %{type: :mouse, action: :press, y: 2}) ==
             {%{model | selected: 2, offset: 1}, {:item, 2, 2, {2, 2}}}

    # retriggers
    assert Select.handle(model, @ev_kp_trigger) ==
             {model, {:item, 0, 0, {0, 0}}}

    # nops
    assert Select.handle(%{}, nil) == {%{}, nil}
    assert Select.handle(initial, %{type: :mouse}) == {initial, nil}
    assert Select.handle(initial, %{type: :key}) == {initial, nil}
    assert Select.handle(model, @ev_kp_kup) == {model, nil}
    assert Select.handle(model, @ev_kp_pup) == {model, nil}
    assert Select.handle(model, @ev_kp_home) == {model, nil}
    assert Select.handle(model, @ev_ms_up) == {model, nil}

    assert Select.handle(%{model | selected: 2}, @ev_kp_kdown) ==
             {%{model | selected: 2, offset: 1}, nil}

    assert Select.handle(%{model | selected: 2}, @ev_kp_pdown) ==
             {%{model | selected: 2, offset: 1}, nil}

    assert Select.handle(%{model | selected: 2}, @ev_kp_end) ==
             {%{model | selected: 2, offset: 1}, nil}

    assert Select.handle(%{model | selected: 2}, @ev_ms_down) ==
             {%{model | selected: 2, offset: 1}, nil}

    assert Select.handle(model, %{type: :mouse, action: :press, y: 0}) ==
             {model, nil}

    assert Select.handle(model, %{type: :mouse, action: :press, y: 3}) ==
             {model, nil}

    # recalculate

    # offset (any key/mouse should correct it)
    assert Select.handle(%{model | selected: -1}, @ev_kp_kup) ==
             {model, {:item, 0, 0, {0, 0}}}

    assert Select.handle(%{model | selected: -1}, @ev_ms_up) ==
             {model, {:item, 0, 0, {0, 0}}}

    assert Select.update(%{model | selected: -1}, selected: 0) == model

    # update items
    assert Select.update(initial, items: [0, 1]) == %{
             initial
             | items: [0, 1],
               selected: -1,
               count: 2,
               map: %{0 => 0, 1 => 1}
           }

    # update items + selected
    assert Select.update(initial, items: [0, 1], selected: 1) == %{
             initial
             | items: [0, 1],
               selected: -1,
               offset: 0,
               count: 2,
               map: %{0 => 0, 1 => 1}
           }

    # update selected + items
    assert Select.update(initial, selected: 1, items: [0, 1]) == %{
             initial
             | items: [0, 1],
               selected: -1,
               offset: 0,
               count: 2,
               map: %{0 => 0, 1 => 1}
           }

    # update items with invalid offset
    assert Select.update(%{initial | selected: 1, offset: 2}, items: [0, 1]) == %{
             initial
             | items: [0, 1],
               selected: -1,
               offset: 0,
               count: 2,
               map: %{0 => 0, 1 => 1}
           }
  end
end
