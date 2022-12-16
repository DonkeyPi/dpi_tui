defmodule Ash.RadioTest do
  use ExUnit.Case
  use TestMacros

  # Radio complex state consists of items and selected properties
  # with internal extra properties: count, and map.
  test "basic radio check" do
    initial = Radio.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             enabled: true,
             findex: 0,
             class: nil,
             items: [],
             selected: -1,
             count: 0,
             map: %{},
             on_change: &Radio.nop/1
           }

    on_change = fn value -> value end

    # 0 1 2
    # 01234
    model = Radio.init(items: [0, 1, 2], size: {7, 1}, on_change: on_change)

    # updates

    # update items
    assert Radio.update(initial, items: [0, 1]) == %{
             initial
             | items: [0, 1],
               selected: 0,
               count: 2,
               map: %{0 => 0, 1 => 1}
           }

    # update items + selected
    assert Radio.update(initial, items: [0, 1], selected: 1) == %{
             initial
             | items: [0, 1],
               selected: 1,
               count: 2,
               map: %{0 => 0, 1 => 1}
           }

    # update selected + items
    assert Radio.update(initial, selected: 1, items: [0, 1]) == %{
             initial
             | items: [0, 1],
               selected: 1,
               count: 2,
               map: %{0 => 0, 1 => 1}
           }

    # reset selected
    assert Radio.update(%{initial | selected: 1}, items: [0, 1]) == %{
             initial
             | items: [0, 1],
               selected: 0,
               count: 2,
               map: %{0 => 0, 1 => 1}
           }

    # triggers

    # right key moves selection to the right
    assert Radio.handle(model, @ev_kp_kright) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    # mouse scroll down moves selection to the right
    assert Radio.handle(model, @ev_ms_down) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    # end key moves selection to the end
    assert Radio.handle(model, @ev_kp_end) ==
             {%{model | selected: 2}, {:item, 2, 2, {2, 2}}}

    # left key moves selection to the left
    assert Radio.handle(%{model | selected: 1}, @ev_kp_kleft) ==
             {model, {:item, 0, 0, {0, 0}}}

    # home key moves selection to the start
    assert Radio.handle(%{model | selected: 2}, @ev_kp_home) ==
             {model, {:item, 0, 0, {0, 0}}}

    # mouse scroll up moves selection to the left
    assert Radio.handle(%{model | selected: 1}, @ev_ms_up) ==
             {model, {:item, 0, 0, {0, 0}}}

    # mouse click sets selection to clicked item
    assert Radio.handle(model, ev_mp_left(2, 0)) ==
             {%{model | selected: 1}, {:item, 1, 1, {1, 1}}}

    # mouse click sets selection to clicked item
    assert Radio.handle(%{model | selected: 2}, ev_mp_left(0, 0)) ==
             {%{model | selected: 0}, {:item, 0, 0, {0, 0}}}

    # retriggers
    assert Radio.handle(model, @ev_kp_trigger) == {model, {:item, 0, 0, {0, 0}}}

    assert Radio.handle(model, @ev_kp_space) == {model, {:item, 0, 0, {0, 0}}}

    # nops

    # left key wont go beyond start
    assert Radio.handle(model, @ev_kp_kleft) == {model, nil}

    # home key wont go beyond start
    assert Radio.handle(model, @ev_kp_home) == {model, nil}

    # mouse scroll up wont go beyond start
    assert Radio.handle(model, @ev_ms_up) == {model, nil}

    # right key wont go beyond end
    assert Radio.handle(%{model | selected: 2}, @ev_kp_kright) == {%{model | selected: 2}, nil}

    # end key wont go beyond end
    assert Radio.handle(%{model | selected: 2}, @ev_kp_end) == {%{model | selected: 2}, nil}

    # mouse scroll down wont go beyond end
    assert Radio.handle(%{model | selected: 2}, @ev_ms_down) == {%{model | selected: 2}, nil}

    # click on selected item is ignored
    assert Radio.handle(%{model | selected: 2}, ev_mp_left(4, 0)) == {%{model | selected: 2}, nil}

    # click on space separator is ignored
    assert Radio.handle(%{model | selected: 2}, ev_mp_left(1, 0)) == {%{model | selected: 2}, nil}

    # click on unused space is ignored
    assert Radio.handle(%{model | selected: 2}, ev_mp_left(5, 0)) ==
             {%{model | selected: 2}, nil}

    # recalculate

    # offset reset to 0 (any key should correct it)
    assert Radio.handle(%{model | selected: -1}, @ev_kp_kleft) ==
             {model, {:item, 0, 0, {0, 0}}}

    # offset reset to 0 (any/mouse should correct it)
    assert Radio.handle(%{model | selected: -1}, @ev_ms_up) ==
             {model, {:item, 0, 0, {0, 0}}}

    # selected explicitly updated to 0
    assert Radio.update(%{model | selected: -1}, selected: 0) == model

    # colors properly applied for each state
    radio(items: [0, 1])
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_normal)
    |> focused(true)
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_focused)
    |> enabled(false)
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_disabled)

    # excess space
    radio(items: [0], size: {2, 2})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" ", 1, @tc_normal)
    |> assert_color("  ", 0, 1, @tc_normal)

    # navigation keyboard
    radio(items: [0, 1, 2])
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_normal)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_kp_kright, {:item, 1, 1, {:nop, {1, 1}}})
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1", 2, @tc_selected)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_kp_kright, {:item, 2, 2, {:nop, {2, 2}}})
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1 ", 2, @tc_normal)
    |> assert_color("2", 4, @tc_selected)
    |> handle(@ev_kp_kright, nil)
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1 ", 2, @tc_normal)
    |> assert_color("2", 4, @tc_selected)
    |> handle(@ev_kp_kleft, {:item, 1, 1, {:nop, {1, 1}}})
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1", 2, @tc_selected)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_kp_kleft, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_normal)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_kp_kleft, nil)
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_normal)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_kp_end, {:item, 2, 2, {:nop, {2, 2}}})
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1 ", 2, @tc_normal)
    |> assert_color("2", 4, @tc_selected)
    |> handle(@ev_kp_home, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_normal)
    |> assert_color(" 2", 3, @tc_normal)

    # navigation mouse
    radio(items: [0, 1, 2])
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_normal)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_ms_down, {:item, 1, 1, {:nop, {1, 1}}})
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1", 2, @tc_selected)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_ms_down, {:item, 2, 2, {:nop, {2, 2}}})
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1 ", 2, @tc_normal)
    |> assert_color("2", 4, @tc_selected)
    |> handle(@ev_ms_down, nil)
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1 ", 2, @tc_normal)
    |> assert_color("2", 4, @tc_selected)
    |> handle(@ev_ms_up, {:item, 1, 1, {:nop, {1, 1}}})
    |> render()
    |> assert_color("0 ", 0, @tc_normal)
    |> assert_color("1", 2, @tc_selected)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_ms_up, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_normal)
    |> assert_color(" 2", 3, @tc_normal)
    |> handle(@ev_ms_up, nil)
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> assert_color(" 1", 1, @tc_normal)
    |> assert_color(" 2", 3, @tc_normal)

    # triggers
    radio(items: [0], size: {1, 1})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> handle(@ev_kp_trigger, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
    |> handle(@ev_kp_space, {:item, 0, 0, {:nop, {0, 0}}})
    |> render()
    |> assert_color("0", 0, @tc_selected)
  end
end
