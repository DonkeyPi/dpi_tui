defmodule CheckboxTest do
  use ExUnit.Case
  use ControlTest

  test "basic checkbox check" do
    ControlTest.common_checks(Checkbox, input?: true)

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
    on_change = fn value -> value end
    model1 = %{on_change: on_change, checked: false}
    model2 = %{on_change: on_change, checked: true}
    assert Checkbox.handle(model1, @ev_mp_left) == {model2, {:checked, true, true}}
    assert Checkbox.handle(model1, @ev_kp_space) == {model2, {:checked, true, true}}
    assert Checkbox.handle(model2, @ev_kp_trigger) == {model2, {:checked, true, true}}
  end
end
