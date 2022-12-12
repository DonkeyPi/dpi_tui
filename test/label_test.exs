defmodule LabelTest do
  use ExUnit.Case
  use ControlTest

  # Labels are simple controls in that they have no complex editable state.
  test "basic label check" do
    ControlTest.common_checks(Label)

    initial = Label.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             class: nil,
             text: ""
           }
  end
end
