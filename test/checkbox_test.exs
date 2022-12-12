defmodule CheckboxTest do
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

    # triggers: left click, space, ctrl+enter
    model1 = %{on_change: &Checkbox.nop/1, checked: false}
    model2 = %{on_change: &Checkbox.nop/1, checked: true}
    assert Checkbox.handle(model1, @ev_mp_left) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model1, @ev_kp_space) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model2, @ev_kp_trigger) == {model2, {:checked, true, {:nop, true}}}

    # colors properly applied for each state
    checkbox(text: "T")
    |> render()
    |> assert("[ ]T", 0, @tcf_normal, @tcb_normal)
    |> focused(true)
    |> render()
    |> assert("[ ]T", 0, @tcf_focused, @tcb_focused)
    |> enabled(false)
    |> render()
    |> assert("[ ]T", 0, @tcf_disabled, @tcb_disabled)

    # top left aligment
    checkbox(text: "T", size: {5, 2})
    |> render()
    |> assert("[ ]T ", 0, @tcf_normal, @tcb_normal)
    |> assert("     ", 1, @tcf_normal, @tcb_normal)

    # excess text
    checkbox(text: "Title", size: {6, 1})
    |> render()
    |> assert("[ ]Tit", 0, @tcf_normal, @tcb_normal)

    # checked state and triggers
    checkbox(text: "T")
    |> handle(@ev_kp_trigger, {:checked, false, {:nop, false}})
    |> render()
    |> assert("[ ]T", 0, @tcf_normal, @tcb_normal)
    |> checked(true)
    |> render()
    |> assert("[X]T", 0, @tcf_normal, @tcb_normal)
    |> handle(@ev_kp_trigger, {:checked, true, {:nop, true}})
    |> render()
    |> assert("[X]T", 0, @tcf_normal, @tcb_normal)
    |> handle(@ev_mp_left, {:checked, false, {:nop, false}})
    |> render()
    |> assert("[ ]T", 0, @tcf_normal, @tcb_normal)
    |> handle(@ev_kp_space, {:checked, true, {:nop, true}})
    |> render()
    |> assert("[X]T", 0, @tcf_normal, @tcb_normal)
    |> handle(@ev_kp_space, {:checked, false, {:nop, false}})
    |> render()
    |> assert("[ ]T", 0, @tcf_normal, @tcb_normal)
    |> handle(@ev_mp_left, {:checked, true, {:nop, true}})
    |> render()
    |> assert("[X]T", 0, @tcf_normal, @tcb_normal)
  end
end
