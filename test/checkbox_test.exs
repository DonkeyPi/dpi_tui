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
    checkbox(text: "T", origin: {1, 1})
    |> render(6, 3)
    |> assert("[ ]T", 1, 1, @tcf_normal, @tcb_normal)
    |> focused(true)
    |> render(6, 3)
    |> assert("[ ]T", 1, 1, @tcf_focused, @tcb_focused)
    |> enabled(false)
    |> render(6, 3)
    |> assert("[ ]T", 1, 1, @tcf_disabled, @tcb_disabled)

    # top left aligment
    checkbox(text: "T", origin: {1, 1}, size: {5, 2})
    |> render(7, 4)
    |> assert("[ ]T ", 1, 1, @tcf_normal, @tcb_normal)
    |> assert("     ", 1, 2, @tcf_normal, @tcb_normal)

    # checked state and triggers
    checkbox(text: "T", origin: {1, 1})
    |> handle(@ev_kp_trigger, {:checked, false, {:nop, false}})
    |> render(6, 3)
    |> assert("[ ]T", 1, 1, @tcf_normal, @tcb_normal)
    |> checked(true)
    |> render(6, 3)
    |> assert("[X]T", 1, 1, @tcf_normal, @tcb_normal)
    |> handle(@ev_kp_trigger, {:checked, true, {:nop, true}})
    |> render(6, 3)
    |> assert("[X]T", 1, 1, @tcf_normal, @tcb_normal)
    |> handle(@ev_mp_left, {:checked, false, {:nop, false}})
    |> render(6, 3)
    |> assert("[ ]T", 1, 1, @tcf_normal, @tcb_normal)
    |> handle(@ev_kp_space, {:checked, true, {:nop, true}})
    |> render(6, 3)
    |> assert("[X]T", 1, 1, @tcf_normal, @tcb_normal)
    |> handle(@ev_kp_space, {:checked, false, {:nop, false}})
    |> render(6, 3)
    |> assert("[ ]T", 1, 1, @tcf_normal, @tcb_normal)
    |> handle(@ev_mp_left, {:checked, true, {:nop, true}})
    |> render(6, 3)
    |> assert("[X]T", 1, 1, @tcf_normal, @tcb_normal)
  end
end
