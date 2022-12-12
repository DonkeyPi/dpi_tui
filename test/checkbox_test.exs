defmodule CheckboxTest do
  use ExUnit.Case
  use Ash.Tui.Aliases
  use Ash.Tui.Events

  # Checkboxs are simple controls in that they have no complex editable state.
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

    # triggers
    model1 = %{on_change: &Checkbox.nop/1, checked: false}
    model2 = %{on_change: &Checkbox.nop/1, checked: true}
    assert Checkbox.handle(model1, @ev_mp_left) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model1, @ev_kp_space) == {model2, {:checked, true, {:nop, true}}}
    assert Checkbox.handle(model2, @ev_kp_trigger) == {model2, {:checked, true, {:nop, true}}}
  end
end
