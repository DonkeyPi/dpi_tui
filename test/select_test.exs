defmodule Dpi.SelectTest do
  use ExUnit.Case
  use TestMacros

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
             stringer: &Select.stringer/1,
             on_action: &Select.nop/1,
             on_change: &Select.nop/1
           }

    Buffer.start()

    on_change = fn value ->
      Buffer.add("on_change #{inspect(value)}")
      value
    end

    on_action = fn value ->
      Buffer.add("on_action #{inspect(value)}")
      value
    end

    model =
      Select.init(items: [0, 1, 2], size: {10, 2}, on_change: on_change, on_action: on_action)

    assert Buffer.get() == "on_change {0, 0}"
    Buffer.start()

    # updates (and on_change triggers)

    # selected explicitly updated
    assert Select.update(%{model | selected: -1}, selected: 0) == model
    assert Buffer.get() == "on_change {0, 0}"
    Buffer.start()

    assert Select.update(%{model | selected: -1}, selected: 1) == %{model | selected: 1}
    assert Buffer.get() == "on_change {1, 1}"
    Buffer.start()

    assert Select.update(model, selected: -1) == %{model | selected: -1}
    assert Buffer.get() == "on_change {-1, nil}"
    Buffer.start()

    assert Select.update(model, selected: -2) == %{model | selected: -1}
    assert Buffer.get() == "on_change {-1, nil}"
    Buffer.start()

    assert Select.update(model, selected: 3) == %{model | selected: -1}
    assert Buffer.get() == "on_change {-1, nil}"
    Buffer.start()

    # update items (zero area)
    assert Select.update(%{initial | on_change: on_change}, items: [0, 1]) == %{
             initial
             | on_change: on_change,
               items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2,
               selected: -1
           }

    assert Buffer.get() == ""
    Buffer.start()

    # update items + size
    assert Select.update(%{initial | on_change: on_change}, size: {0, 2}, items: [0, 1]) == %{
             initial
             | on_change: on_change,
               size: {0, 2},
               items: [0, 1],
               map: %{0 => 0, 1 => 1},
               count: 2,
               selected: 0
           }

    assert Buffer.get() == "on_change {0, 0}"
    Buffer.start()

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
    Buffer.start()

    assert Select.handle(model, @ev_kp_enter_ctrl) == {model, {:item, 0, 0, {0, 0}}}
    assert Buffer.get() == "on_action {0, 0}"
    Buffer.start()

    assert Select.handle(model, @ev_kp_space) == {model, {:item, 0, 0, {0, 0}}}
    assert Buffer.get() == "on_action {0, 0}"
    Buffer.start()

    assert Select.handle(model, Map.put(@ev_ms_click_ctrl, :y, 0)) ==
             {model, {:item, 0, 0, {0, 0}}}

    assert Buffer.get() == "on_action {0, 0}"
    Buffer.start()

    assert Select.handle(model, Map.put(@ev_ms_dblclick, :y, 0)) == {model, {:item, 0, 0, {0, 0}}}
    assert Buffer.get() == "on_action {0, 0}"
    Buffer.start()

    assert Select.handle(model, Map.put(@ev_ms_click_ctrl, :y, 1)) == {model, nil}
    assert Select.handle(model, Map.put(@ev_ms_dblclick, :y, 1)) == {model, nil}

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

    # colors properly applied for each state
    select(items: [0, 1])
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)
    |> focused(true)
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_focused)
    |> enabled(false)
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_disabled)

    # extra space
    select(items: [0], size: {1, 2})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" ", 1, @tc_normal)

    # excess text (checks nothing)
    select(items: ["012"], size: {2, 1})
    |> render()
    |> assert_color("01", 0, @tc_selected)

    # excess space
    select(items: [0], size: {2, 1})
    |> render()
    |> assert_color("0 ", 0, @tc_selected)

    # selection navigation keyboard
    select(items: [0, 1, 2, 3, 4, 5], size: {1, 2})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)
    # navigate first chunk with arrows
    |> handle(@ev_kp_kdown, {:item, 1, 1, {:nop, {1, 1}}})
    |> render()
    |> assert_color("0", 0, @tc_normal)
    |> assert_color("1", 1, @tc_selected)
    |> handle(@ev_kp_kdown, {:item, 2, 2, {:nop, {2, 2}}})
    |> render()
    |> assert_color("1", 0, @tc_normal)
    |> assert_color("2", 1, @tc_selected)
    # continue with page jumps
    |> handle(@ev_kp_pdown, {:item, 4, 4, {:nop, {4, 4}}})
    |> render()
    |> assert_color("3", 0, @tc_normal)
    |> assert_color("4", 1, @tc_selected)
    |> handle(@ev_kp_pdown, {:item, 5, 5, {:nop, {5, 5}}})
    |> render()
    |> assert_color("4", 0, @tc_normal)
    |> assert_color("5", 1, @tc_selected)
    # renavigate last chunk with arrows
    |> selected(4)
    |> render()
    |> assert_color("4", 0, @tc_selected)
    |> assert_color("5", 1, @tc_normal)
    |> handle(@ev_kp_kdown, {:item, 5, 5, {:nop, {5, 5}}})
    |> render()
    |> assert_color("4", 0, @tc_normal)
    |> assert_color("5", 1, @tc_selected)
    |> handle(@ev_kp_kdown, nil)
    |> render()
    |> assert_color("4", 0, @tc_normal)
    |> assert_color("5", 1, @tc_selected)
    # nagivate back first chunk with arrows
    |> handle(@ev_kp_kup, {:item, 4, 4, {:nop, {4, 4}}})
    |> render()
    |> assert_color("4", 0, @tc_selected)
    |> assert_color("5", 1, @tc_normal)
    |> handle(@ev_kp_kup, {:item, 3, 3, {:nop, {3, 3}}})
    |> render()
    |> assert_color("3", 0, @tc_selected)
    |> assert_color("4", 1, @tc_normal)
    # continue with page jumps
    |> handle(@ev_kp_pup, {:item, 1, 1, {:nop, {1, 1}}})
    |> render()
    |> assert_color("1", 0, @tc_selected)
    |> assert_color("2", 1, @tc_normal)
    |> handle(@ev_kp_pup, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)
    # renavigate last chunk with arrows
    # force offset = 1 with double select below
    |> selected(2)
    |> selected(1)
    |> render()
    |> assert_color("1", 0, @tc_selected)
    |> assert_color("2", 1, @tc_normal)
    |> handle(@ev_kp_kup, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)
    |> handle(@ev_kp_kup, nil)
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)

    # selection navigation mouse wheel
    select(items: [0, 1, 2, 3, 4, 5], size: {1, 2})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)
    # navigate first chunk with arrows
    |> handle(@ev_ms_down, {:item, 1, 1, {:nop, {1, 1}}})
    |> render()
    |> assert_color("0", 0, @tc_normal)
    |> assert_color("1", 1, @tc_selected)
    |> handle(@ev_ms_down, {:item, 2, 2, {:nop, {2, 2}}})
    |> render()
    |> assert_color("1", 0, @tc_normal)
    |> assert_color("2", 1, @tc_selected)
    # continue with page jumps
    |> handle(@ev_ms_pdown, {:item, 4, 4, {:nop, {4, 4}}})
    |> render()
    |> assert_color("3", 0, @tc_normal)
    |> assert_color("4", 1, @tc_selected)
    |> handle(@ev_ms_pdown, {:item, 5, 5, {:nop, {5, 5}}})
    |> render()
    |> assert_color("4", 0, @tc_normal)
    |> assert_color("5", 1, @tc_selected)
    # renavigate last chunk with arrows
    |> selected(4)
    |> render()
    |> assert_color("4", 0, @tc_selected)
    |> assert_color("5", 1, @tc_normal)
    |> handle(@ev_ms_down, {:item, 5, 5, {:nop, {5, 5}}})
    |> render()
    |> assert_color("4", 0, @tc_normal)
    |> assert_color("5", 1, @tc_selected)
    |> handle(@ev_ms_down, nil)
    |> render()
    |> assert_color("4", 0, @tc_normal)
    |> assert_color("5", 1, @tc_selected)
    # nagivate back first chunk with arrows
    |> handle(@ev_ms_up, {:item, 4, 4, {:nop, {4, 4}}})
    |> render()
    |> assert_color("4", 0, @tc_selected)
    |> assert_color("5", 1, @tc_normal)
    |> handle(@ev_ms_up, {:item, 3, 3, {:nop, {3, 3}}})
    |> render()
    |> assert_color("3", 0, @tc_selected)
    |> assert_color("4", 1, @tc_normal)
    # continue with page jumps
    |> handle(@ev_ms_pup, {:item, 1, 1, {:nop, {1, 1}}})
    |> render()
    |> assert_color("1", 0, @tc_selected)
    |> assert_color("2", 1, @tc_normal)
    |> handle(@ev_ms_pup, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)
    # renavigate last chunk with arrows
    # force offset = 1 with double select below
    |> selected(2)
    |> selected(1)
    |> render()
    |> assert_color("1", 0, @tc_selected)
    |> assert_color("2", 1, @tc_normal)
    |> handle(@ev_ms_up, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)
    |> handle(@ev_ms_up, nil)
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color("1", 1, @tc_normal)

    # triggers
    select(items: [0], size: {1, 1})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> handle(@ev_kp_enter_ctrl, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> handle(@ev_kp_space, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
  end
end
