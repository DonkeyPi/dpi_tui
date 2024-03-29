defmodule Dpi.CheckboxTest do
  use ExUnit.Case
  use TestMacros

  # Checkboxs have no complex editable state.
  test "basic checkbox check" do
    initial = Checkbox.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {3, 1},
             visible: true,
             enabled: true,
             findex: 0,
             class: nil,
             text: "",
             checked: false,
             on_change: &Checkbox.nop/1
           }

    Buffer.start()

    on_change = fn value ->
      Buffer.add("#{value}")
      value
    end

    Checkbox.init(on_change: on_change, checked: false)
    assert Buffer.get() == ""
    Buffer.start()

    model = Checkbox.init(on_change: on_change, checked: true)
    assert Buffer.get() == "true"
    Buffer.start()

    model = Checkbox.update(model, checked: true)
    assert Buffer.get() == ""
    Buffer.start()

    model = Checkbox.update(model, checked: false)
    assert Buffer.get() == "false"
    Buffer.start()

    model = Checkbox.update(model, checked: false)
    assert Buffer.get() == ""
    Buffer.start()

    Checkbox.update(model, checked: true)
    assert Buffer.get() == "true"
    Buffer.start()

    # triggers: left click, space, ctrl+enter
    model1 = %{on_change: &Checkbox.nop/1, checked: false}
    model2 = %{on_change: &Checkbox.nop/1, checked: true}
    assert Checkbox.handle(model1, ev_mp_left(0, 0)) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model1, ev_mp_left(1, 1)) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model1, ev_mp_left(-1, -1)) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model1, @ev_kp_space) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model2, @ev_kp_enter_ctrl) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model2, @ev_ms_click_ctrl) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model2, @ev_ms_dblclick) == {model2, {:checked, true, {:nop, true}}}

    # colors properly applied for each state
    checkbox(text: "T")
    |> render()
    |> assert_color("[ ]T", 0, @tc_normal)
    |> focused(true)
    |> render()
    |> assert_color("[ ]T", 0, @tc_focused)
    |> enabled(false)
    |> render()
    |> assert_color("[ ]T", 0, @tc_disabled)

    # top left aligment
    checkbox(text: "T", size: {5, 2})
    |> render()
    |> assert_color("[ ]T ", 0, @tc_normal)
    |> assert_color("     ", 1, @tc_normal)

    # excess text
    checkbox(text: "Title", size: {6, 1})
    |> render()
    |> assert_color("[ ]Tit", 0, @tc_normal)

    # triggers
    checkbox(text: "T")
    |> handle(@ev_kp_enter_ctrl, {:checked, false, {:nop, false}})
    |> render()
    |> assert_color("[ ]T", 0, @tc_normal)
    |> checked(true)
    |> render()
    |> assert_color("[X]T", 0, @tc_normal)
    |> handle(@ev_kp_enter_ctrl, {:checked, true, {:nop, true}})
    |> render()
    |> assert_color("[X]T", 0, @tc_normal)
    |> handle(ev_mp_left(0, 0), {:checked, false, {:nop, false}})
    |> render()
    |> assert_color("[ ]T", 0, @tc_normal)
    |> handle(@ev_kp_space, {:checked, true, {:nop, true}})
    |> render()
    |> assert_color("[X]T", 0, @tc_normal)
    |> handle(@ev_kp_space, {:checked, false, {:nop, false}})
    |> render()
    |> assert_color("[ ]T", 0, @tc_normal)
    |> handle(ev_mp_left(0, 0), {:checked, true, {:nop, true}})
    |> render()
    |> assert_color("[X]T", 0, @tc_normal)
  end
end
